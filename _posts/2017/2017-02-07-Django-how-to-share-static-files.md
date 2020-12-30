---
comments: true
date: 2017-02-07
layout: post
tags: [Tech]
title: How to Share Static Files in Django
---

When I was working on my Django project I came across the situation that multiple apps were actually using the same static files. Being a software engineer who has been taught about the [DRY(Don't Repeat Yourself)](https://en.wikipedia.org/wiki/Don't_repeat_yourself) principle through the entire career, I figured out the solution to share these files by reading someone else's blog as well as skimming through the Django documents.

The solution consists of the following steps:

* Add the _STATICFILES_DIRS_ variable to the project's _settings.py_ file.
* Put the static files to a shared location.
* Modify the HTML templates, if necessary, to use the files in the shared location.

Here are more details about each step. Please note that this article is written on the basis of the [Django's official tutorials](https://docs.djangoproject.com/en/1.10/intro/tutorial01/) so it should work for you if you also base your work on the same tutorial.

## Step 1: Add the _STATICFILES_DIRS_ Variable

In the project's _settings.py_ file, you should be able to find a variable at the end of it:

```python
# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/1.10/howto/static-files/

STATIC_URL = '/static/'
```

Add another Python list after it:

```python
STATICFILES_DIRS = [
    os.path.join(BASE_DIR, "__shared__"),
]
```

This tells Django to search for static files in addition to the path specified in _STATIC_URL_. The relevant document is here: [STATICFILES_DIRS](https://docs.djangoproject.com/en/1.10/ref/settings/#staticfiles-dirs).

## Step 2: Put the Static Files to the Shared Location

In Step 1, the _BASE_DIR_ is defined in the _settings.py_ as well:

```python
# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
```

If you are following Django's tutorial, in which the sample project has the following structure:

```
mysite/
    manage.py
    mysite/
        __init__.py
        settings.py
        urls.py
        wsgi.py
```

The _BASE_DIR_ points to the _mysite_ inside the outer _mysite_. Therefore, the additional static file location we added in Step 1 should be:

```text
mysite/mysite/__shared__
```

So let's create this directory and make the directory structure look like below:

```text
mysite/
    __shared__/
        images/
            background.png
        style.css
    manage.py
    mysite/
        __init__.py
        settings.py
        urls.py
        wsgi.py
```

## Step 3: Modify the HTML Templates

The HTML templates in Django's official tutorials refer to the static files as follows:

HTML pages:

{% raw %}
```html
<link rel="stylesheet" type="text/css" href="{% static 'polls/style.css' %}" />
```
{% endraw %}

style.css:

```css
body {
    background: white url("images/background.png") no-repeat right bottom;
}
```

You need to adjust the relative paths accordingly. For example, because now we've put the _style.css_ immediately under the ___shared____ directory without any intermediate sub-directories, we should no longer use the _polls_ directory, so we should modify the HTML template as:

{% raw %}
```html
<link rel="stylesheet" type="text/css" href="{% static 'style.css' %}" />
```
{% endraw %}

When Django's static file finder looks for the style.css as specified in the code {% raw %} ```{% static "style.css" %}``` {% endraw %}, it first searches in the _static_ directory of that app. Because this directory doesn't exist after we move the static files to the shared location, the finder then searches the additional static file folders which contains ___shared____, and is able to find and use it. If we don't remove the intermediate _polls_, the finder cannot find the file *__shared__/polls/style.css*.

## More Notes

I also read the blog [Share static files between apps in Django](http://vincesalvino.blogspot.com/2013/02/share-static-files-between-apps-in.html). However, this article doesn't discuss how to modify the HTML template accordingly. The template refers to the _style.css_ with {% raw %}```{{STATIC_URL}}/style.css```{% endraw %} which doesn't work because _STATIC_URL_ is always _static_ and doesn't include the newly added _common-static_ in.
