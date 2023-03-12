---
comments: true
date: 2023-01-08
layout: post
tags: [Tech;Frontend;JavaScript;Async;Promise]
title: "JavaScript: How to implement a Promise with timeout (and cancelation)"
---

JavaScript's native `Promise` doesn't support timeout [1], but sometimes we do want to set a time limit to the promises and get a notification when the time limit is exceeded. Therefore, as part of my effort of learning JavaScript, I used `Promise.race()` to implement the timeout mechanism for a Promise:

```javascript
// NOTE(ywen): For demo purpose, the code does not do error handling (such as
// validating the input arguments).
//
// Arguments:
// - timeout_ms: The timeout in milliseconds.
// - prom: The promise to run.
// - on_fulfill: The callback when `prom` can fulfill before timeout. It has
//    the same signature as the `then`'s `onFulfillment` callback:
//    `value => {...}`.
// - on_reject: The callback when `prom` is rejected before timeout. It has the
//    same signature as the `then`'s `onRejection` callback: `reason => {...}`.
// - on_timeout: The callback to handle the timeout event. It has the signature
//    of `(promise, timeout_ms) => {...}`.
//
// Return:
// - A promise that is fulfilled/rejected when `prom` is fulfilled/rejected.
function TimeoutPromise(timeout_ms, prom, on_fulfill, on_reject, on_timeout) {
  let tid = -1
  let timeout = new Promise((undefined, reject) => {
    tid = setTimeout(() => {
      on_timeout(prom, timeout_ms)
      reject("Timeout")
    }, timeout_ms)
  })

  let p = Promise.race([prom, timeout])
    .then(on_fulfill)
    .catch(on_reject)
    .finally(() => {
      clearTimeout(tid)
    })

  return p
}
```

One thing to consider when using `TimeoutPromise` is: **When the timeout happens, what should happen to `prom`? Should it continue running until it's resolved? Or should it be canceled?**

I think `prom` should be canceled **most of the time (but not all the time because there must be some exceptions)**, because usually when we want to implement timeout for a promise, we want to make sure we can get the promise result before a certain time limit. When the time limit is exceeded, the promise result may no longer make sense to us, so we should just cancel the promise (unless the continuous execution of the promise doesn't do any harm).

Unfortunately, native promises can be either fulfilled or rejected, but can't be canceled [2]. Therefore, when you want to implement a promise with timeout, you also need to think how to implement cancelation for the promise (if you do not use a 3rd-party library as [2] suggests).

Implementing cancelation can be quite flexible without a universal method, because every promise can be different, and you must choose the most appropriate way for each promise. The example [`timeout.js`](https://github.com/yaobinwen/robin_on_rails/blob/master/JavaScript/Promise/timeout.js) shows three examples of cancelling promises.

One more thing to note is: When you use `Promise.all()` to protect a group of promises with a timeout, it's important to remember to cancel the other promises when [one is rejected](https://github.com/yaobinwen/robin_on_rails/blob/master/JavaScript/Promise/timeout.js#L138-L144):

```javascript
  (reason) => {
    // When one promise gets rejected, we need to cancel the others because
    // otherwise they will keep running until resolved.
    cancel1 = true
    cancel2 = true
    console.error("rejected: ", reason)
  },
```

References:
- [1] [Stack Overflow: NodeJS Timeout a Promise if failed to complete in time](https://stackoverflow.com/q/32461271/630364)
- [2] [Stack Overflow: Promise - is it possible to force cancel a promise](https://stackoverflow.com/a/30235261/630364)
