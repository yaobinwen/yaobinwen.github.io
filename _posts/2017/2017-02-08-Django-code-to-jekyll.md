---
comments: true
date: 2017-02-08
layout: post
tags: [Tech]
title: How to Embed Django Template Code in Jekyll
---

> The key is to use the "raw" tag in the Liquid template language.

Yesterday when I wrote the blog about [how to share static files between Django apps](http://yaobinwen.github.io/archive/2017/02/07/Django-how-to-share-static-files/), I was trying to embed some Django template code in the article, like below:

![Django template code](https://raw.githubusercontent.com/yaobinwen/yaobinwen.github.io/master/images/2017/02-08/Django_code.png)

Later I got an email saying the page building failed because of the unrecognized tag "_static_". I tried several fixes before I realized it might be caused by the embedded Django template code.

The real reason is that [Jekyll](https://jekyllrb.com/), the static website generator I'm using to build this blog, uses a template language called [Liquid](https://shopify.github.io/liquid/) which also uses "{% raw %}{%{% endraw %}" and "{% raw %}%}{% endraw %}" to enclose a tag to be evaluated. Because _static_ is not a tag in Liquid, an error is reported when the Jekyll engines came across this snippet of code.

The solution is to use the _raw_ tag, which is explained [here](https://github.com/Shopify/liquid/wiki/Liquid-for-Designers#raw),  to enclose the Django template code:

![Django template code in raw](https://raw.githubusercontent.com/yaobinwen/yaobinwen.github.io/master/images/2017/02-08/Django_code_in_raw.png)

Then the page can be generated as expected.
