---
comments: true
date: 2022-02-18
layout: post
tags: [Tech]
title: "Why does Google Chrome automatically redirect `http://app` to `https://app` but doesn't do that to `http://app2` or `http://napp`?"
---

Days ago, when I was working on the work project, I wanted to put an entry `127.0.0.1 app` in `/etc/hosts` in order to open `http://app` in the browser instead of using the IP address `127.0.0.1`. When I did this, I was surprised that Google Chrome would automatically redirect `http://app` to `https://app`.

After searching for the possible reasons for a while, eventually, I asked the question [_Why does Google Chrome automatically redirect `http://app` to `https://app` but doesn't do that to `http://app2` or `http://napp`?_](https://stackoverflow.com/q/71036570/630364) on Stack Overflow. Because nobody answered the question after a few days, I forwarded the question to the [_chromium-discuss_ email group](https://groups.google.com/a/chromium.org/g/chromium-discuss/c/8vdnQaM3Iok/m/bPFOm5_OAAAJ).

Under that email thread, another user replied me saying I could check the redirection activities in the "Network" tab in Chrome's "Developer tools". I did that. After I entered `http://app`, I found one of the lines said "Status: 307" which means an internal redirect. When I clicked on that line, another tab was open for me to examine the details. In the `Headers` tab, a line told the reason: "Non-Authoritative-Reason: HSTS".

Google brought me to [this answer](https://stackoverflow.com/a/45630216/630364) which mentions the [HSTS Preload List](https://hstspreload.org), which says:

> This form is used to submit domains for inclusion in Chrome's HTTP Strict Transport Security (HSTS) preload list. This is a list of sites that are **hardcoded into Chrome as being HTTPS only**.

So I entered `app` and found its status is ["app is currently preloaded"](https://hstspreload.org/?domain=app). But `app2` and `napp` were "not preloaded". This is why Google Chrome automatically redirects `http://app` to `https://app` but doesn't do that to `http://app2` or `http://napp`.

Some further search brought me to the page [_HTTP Strict Transport Security_](https://www.chromium.org/hsts/) on _The Chromium Projects_. This page also provides [the link to the `.json` file](https://source.chromium.org/chromium/chromium/src/+/main:net/http/transport_security_state_static.json) that stores all the hardcoded addresses.

Because the original file is very large, about 17MB as of 2022-02-18, I put [a compressed copy here](../../files/2022/transport_security_state_static-2022-02-18.txz) for easier reference in the future.

At the beginning of `transport_security_state_static.json`, I found the following lines:

```json
...
// gTLDs and eTLDs are welcome to preload if they are interested.
{ "name": "android", "policy": "public-suffix", "mode": "force-https", "include_subdomains": true },
{ "name": "app", "policy": "public-suffix", "mode": "force-https", "include_subdomains": true },
...
```

So the gTLD (generic top-level domain) `app` is forced to get redirected to its `HTTPS` counterpart. This is what the article [_Introducing .app, a more secure home for apps on the web_](https://blog.google/technology/developers/introducing-app-more-secure-home-apps-web/) talks about.

But if `app` is an gTLD, the domain names such as `foo.app` should be impacted, but why is `http://app` also redirected? In fact, this is an intentional behavior as discussed in [_Issue 794202: Should HSTS Preload List affect unqualified hostnames?_](https://bugs.chromium.org/p/chromium/issues/detail?id=794202):

> I feel this is working as Intended. Such intranet sites are themselves broken by virtue of ICANN's policies around delegating them in the first place. We also have in place the ICANN transition to warn users, particularly for cases like http://foo.dev
>
> Unqualified hostnames should never be able to opt-in to HSTS. As a result of ICANN's policy decisions, unqualified hostnames are effectively 'squatters', and should be considered deprecated and, as captured in SSAC policy, a security risk.

A follow-up comment says "to avoid confusion, when writing HSTS names I write, say, `(*.)dev` and `(*.)app` in order to try and convey exactly what is covered".

But surely not everyone is happy about the reinforcement. In [this article](https://misty.moe/2019/07/31/fuck-google-chromes-hsts-feature), the author hated the feature so much that he/she figured out the way to patch the _DLL_ to disable this redirection feature: it's nice to learn how to hack the browser, but it's definitely insecure to work around the feature. Anyway, HSTS is reinforced for a reason.

Last but not least, Chrome's built-in address to configure HSTS is [`chrome://net-internals/#hsts`](chrome://net-internals/#hsts).
