---
comments: true
date: 2017-05-09
layout: post
tags: [Tech]
title: Python Variable Arguments
---

I learned the ```*args``` and ```**kwargs``` several times but never really remember them so this time I'll take the note in my blog.

Say that we have a Python script defined as follows:

```python
def func1(*args, **kwargs):
    print ">>> args:"
    print args
    print args.__class__

    print ">>> kwargs:"
    print kwargs
    print kwargs.__class__

func1(10, "a", {}, robin="robin", sarah="sarah")
```

The following table summarizes what they are:

| Argument | Type | Value |
|:--------:|:----:|:------|
| args | tuple | (10, 'a', {}) |
| kwargs | dict | {'sarah': 'sarah', 'robin': 'robin'} |

Say if we have another function that accepts variable positional arguments and keyword arguments:

```python
def func2(*args, **kwargs):
    print "=== args:"
    print args
    print args.__class__

    print "=== kwargs:"
    print kwargs
    print kwargs.__class__
```

If we want to call ```func2``` from ```func1```, we can't simply call like below

```python
func2(args, kwargs)
```

because ```args``` and ```kwargs``` will be considered as two positional arguments so in ```func2```'s ```args``` will be a tuple that has ```func1```'s ```args``` and ```kwargs``` and ```func2```'s ```kwargs``` will be just an empty ```dict```.

Instead, use the ```*``` and ```**``` to **unpack** the ```args``` and ```kwargs``` before passing into ```func2```:

```python
func2(*args, **kwargs)
```

Then in ```func2```, ```args``` and ```kwargs``` will have the same values as in ```func1```.
