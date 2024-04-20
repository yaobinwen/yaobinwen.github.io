---
comments: true
date: 2024-04-19
layout: post
tags: [Tech, HTTP]
title: HTTP 408 (Request Timeout) and browser auto-retry
---

These days I've been working on a web-based project in which the frontend (in the browser) polls the backend for events with a timeout, meaning, if no event happens within a certain period of time, the backend returns a timeout code.

In an initial implementation, the backend returned the HTTP `408` (Request Timeout) if there was no event within the period of time. When I read the backend logs, I noticed that the backend seemed to received multiple requests even though I only sent exactly one request from the frontend:

```
...
...
INFO:srv_events_long_poll.py:handling '/events/poll' request (handler: 140171347622040; timeout: 3.0)...
WARNING:tornado.access:408 GET /events/poll?timeout-in-s=3 (192.0.2.1) 3003.43ms
ERROR:srv_events_long_poll.py:finishing '/events/poll' request with error
INFO:srv_events_long_poll.py:handling '/events/poll' request (handler: 140171347622488; timeout: 3.0)...
WARNING:tornado.access:408 GET /events/poll?timeout-in-s=3 (192.0.2.1) 3002.31ms
ERROR:srv_events_long_poll.py:finishing '/events/poll' request with error
INFO:srv_events_long_poll.py:handling '/events/poll' request (handler: 140171347622096; timeout: 3.0)...
WARNING:tornado.access:408 GET /events/poll?timeout-in-s=3 (192.0.2.1) 3001.80ms
ERROR:srv_events_long_poll.py:finishing '/events/poll' request with error
...
...
```

In these logs:

- The frontend sent the request with a timeout of 3 seconds.
- The backend printed "handling ... request" right after it received the request, and printed "finishing ..." right before it responded.

I was confused and didn't understand why there were multiple requests. So I examined the technology stack I used in the frontend:

- React.js for UI.
- JavaScript module `axios` to send requests.
- Envoy proxy to route requests and responses.
- Chrome browser.

To further narrow down the scope, I did the following experiments:

|               Call method | No Envoy | Behind Envoy | Problem cause                                                |
| ------------------------: | :------: | :----------: | :----------------------------------------------------------- |
|                    `curl` | No retry |   No retry   | Not in the backend or Envoy.                                 |
|        `nodejs` + `axios` | No retry |   No retry   | Not in `axios` or Envoy.                                     |
|                In browser | Retries  |   Retries    | Possibly in the browser.                                     |
| In browser (HTTP 400/500) | No retry |   No retry   | Not the browser; possibly due to the returned HTTP code 408. |

It turned out to be that I was using the inappropriate HTTP code `408` (Request Timeout). According to [RFC 9110](https://datatracker.ietf.org/doc/html/rfc9110#name-408-request-timeout), `408 Request Timeout` indicates that:

> ... the server did not receive a complete request message within the time that it was prepared to wait.
>
> If the client has an outstanding request in transit, it **MAY** repeat that request. If the current connection is not usable (e.g., as it would be in HTTP/1.1 because request delimitation is lost), a new connection will be used.

So `408` should be used only when the server fails to receive the full request, which implies that the server has not started to process the request at all. But in my case, the backend had received the full request. It was the backend that wasn't able to produce anything before the specified timeout. Because the cause of the timeout was on the server side, it would be more appropriate to use a 5xx HTTP code (depending on if the timeout should be treated as an error).

As a matter of fact, browsers like Chrome and FireFox implement the behavior that, if receiving `408` from the server, they will automatically re-send the request because it should be safe to do so (i.e., the request is not processed at all so the server's state should be still consistent and, per RFC 9110, the client "MAY repeat that request").

## Chrome

Chrome implemented the "retry" behavior in [Issue 303443011: _Retry requests on reused sockets when receiving 408 responses_](https://codereview.chromium.org/303443011) which fixed the [Bug 41110072: _Chromium does not handle 408 responses_](https://issues.chromium.org/issues/41110072). The code changes in this bug fix was as follows:

```diff
Index: net/http/http_network_transaction.cc
diff --git a/net/http/http_network_transaction.cc b/net/http/http_network_transaction.cc
index d9397e4cfbc30dd4f8eab5fb3cf1e5233b277590..14ed89b0d495cee0b75fe54c1ca833b1134f6e36 100644
--- a/net/http/http_network_transaction.cc
+++ b/net/http/http_network_transaction.cc
@@ -987,6 +987,19 @@ int HttpNetworkTransaction::DoReadHeadersComplete(int result) {

   DCHECK(response_.headers.get());

+  // On a 408 response from the server ("Request Timeout") on a stale socket,
+  // retry the request.
+  if (response_.headers->response_code() == 408 &&
+      stream_->IsConnectionReused()) {
+    net_log_.AddEventWithNetErrorCode(
+        NetLog::TYPE_HTTP_TRANSACTION_RESTART_AFTER_ERROR,
+        response_.headers->response_code());
+    // This will close the socket - it would be weird to try and reuse it, even
+    // if the server doesn't actually close it.
+    ResetConnectionAndRequestForResend();
+    return OK;
+  }
+
 #if defined(SPDY_PROXY_AUTH_ORIGIN)
   // Server-induced fallback; see: http://crbug.com/143712
   if (response_.was_fetched_via_proxy) {
```

## FireFox

FireFox implemented the "retry" behavior in [Bug 907800: _Retries requests that receive a 408 Request Timeout response_](https://bugzilla.mozilla.org/show_bug.cgi?id=907800), as the developer said:

> The only tricky thing here is that in the case of a persistent connection reuse we can read a 408 that is basically a race condition against sending the request - in which case a retry is a good thing.
>
> so here's the compromise - I'll change this logic to be
>
> 408 AND reused-pconn AND short-elapsed-time
>
> which I think will serve both use cases.

The main changes were:

```diff
diff --git a/netwerk/protocol/http/nsHttpConnection.cpp b/netwerk/protocol/http/nsHttpConnection.cpp
--- a/netwerk/protocol/http/nsHttpConnection.cpp
+++ b/netwerk/protocol/http/nsHttpConnection.cpp
@@ -697,41 +697,51 @@ nsHttpConnection::OnHeadersAvailable(nsA
 {
     LOG(("nsHttpConnection::OnHeadersAvailable [this=%p trans=%p response-head=%p]\n",
         this, trans, responseHead));

     MOZ_ASSERT(PR_GetCurrentThread() == gSocketThread);
     NS_ENSURE_ARG_POINTER(trans);
     MOZ_ASSERT(responseHead, "No response head?");

-    // If the server issued an explicit timeout, then we need to close down the
-    // socket transport.  We pass an error code of NS_ERROR_NET_RESET to
-    // trigger the transactions 'restart' mechanism.  We tell it to reset its
-    // response headers so that it will be ready to receive the new response.
-    uint16_t responseStatus = responseHead->Status();
-    if (responseStatus == 408) {
-        Close(NS_ERROR_NET_RESET);
-        *reset = true;
-        return NS_OK;
-    }
-
     // we won't change our keep-alive policy unless the server has explicitly
     // told us to do so.

     // inspect the connection headers for keep-alive info provided the
     // transaction completed successfully. In the case of a non-sensical close
     // and keep-alive favor the close out of conservatism.

     bool explicitKeepAlive = false;
     bool explicitClose = responseHead->HasHeaderValue(nsHttp::Connection, "close") ||
         responseHead->HasHeaderValue(nsHttp::Proxy_Connection, "close");
     if (!explicitClose)
         explicitKeepAlive = responseHead->HasHeaderValue(nsHttp::Connection, "keep-alive") ||
             responseHead->HasHeaderValue(nsHttp::Proxy_Connection, "keep-alive");

+    // deal with 408 Server Timeouts
+    uint16_t responseStatus = responseHead->Status();
+    static const PRIntervalTime k1000ms  = PR_MillisecondsToInterval(1000);
+    if (responseStatus == 408) {
+        // If this error could be due to a persistent connection reuse then
+        // we pass an error code of NS_ERROR_NET_RESET to
+        // trigger the transactions 'restart' mechanism.  We tell it to reset its
+        // response headers so that it will be ready to receive the new response.
+        if (mIsReused && ((PR_IntervalNow() - mLastWriteTime) < k1000ms)) {
+            Close(NS_ERROR_NET_RESET);
+            *reset = true;
+            return NS_OK;
+        }
+
+        // timeouts that are not caused by persistent connection reuse should
+        // not be retried for broswer compatibility reasons. bug 907800. The
+        // server driven close is implicit in the 408.
+        explicitClose = true;
+        explicitKeepAlive = false;
+    }
+
     // reset to default (the server may have changed since we last checked)
     mSupportsPipelining = false;
```

## Go programming language

The Go programming language's HTTP request probably implemented the same behavior, as [this answer](https://stackoverflow.com/a/68491872/630364) describes:

> Lets start from method `is408Message()` which is [here](https://github.com/golang/go/blob/052da5717e02659da49707873b3868fe36f2aaf0/src/net/http/transport.go#L2256). It checks that the buffer carries `408 Request timeout` status code. This method is used by another [method](https://github.com/golang/go/blob/052da5717e02659da49707873b3868fe36f2aaf0/src/net/http/transport.go#L2238) to inspect the response from server and in case of `408 Request Timeout` the `persistConn` is closed with an `errServerClosedIdle` error. The error is [assigned](https://github.com/golang/go/blob/052da5717e02659da49707873b3868fe36f2aaf0/src/net/http/transport.go#L2702) to `persistConn.closed` field.
>
> In the [main loop](https://github.com/golang/go/blob/052da5717e02659da49707873b3868fe36f2aaf0/src/net/http/transport.go#L561) of http `Transport`, there is a call to `persistConn.roundTrip` [here](https://github.com/golang/go/blob/052da5717e02659da49707873b3868fe36f2aaf0/src/net/http/transport.go#L594) which as an error returns the value stored in `persistConn.closed` field. Few lines [below](https://github.com/golang/go/blob/052da5717e02659da49707873b3868fe36f2aaf0/src/net/http/transport.go#L606) you can find a method called `pconn.shouldRetryRequest` which takes as an argument the error returned by `persistConn.roundTrip` and returns true when the error is `errServerClosedIdle`. Since the whole operation is wrapped by the for loop the request will be sent again.
>
> It could be valuable for you to analyze [`shouldRetryRequest` method](https://github.com/golang/go/blob/052da5717e02659da49707873b3868fe36f2aaf0/src/net/http/transport.go#L681) because there are multiple conditions which must be met to retry the request. For example the request will not be repeated when the connection was used for the first time.
