---
comments: true
date: 2025-02-04
layout: post
tags: [Tech,Python]
title: "When do Python decorators get called?"
---

I was curious when the Python decorators get called so I wrote the following simple Python program to test it.

```python
#!/usr/bin/python3

import functools

print(f"(1) running module {__file__}")

print("(2a)")


def log_start_end(func):
    print(f"starting decorator {log_start_end.__name__} decorating {func.__name__}...")

    @functools.wraps(func)
    def wrapper(*args, **kwds):
        print(f"calling {func.__name__}...")
        func(*args, **kwds)
        print(f"returned from {func.__name__}")

    print(f"returning decorator {log_start_end.__name__} decorating {func.__name__}...")
    return wrapper


print(f"(2b) after {log_start_end.__name__} is defined")

print("(3a)")


@log_start_end
def func1():
    print("func1")


print(f"(3b) after {func1.__name__} is defined")

print("(4a)")


class C(object):
    @log_start_end
    def hello(self, name):
        print(f"hello, {name}")


print(f"(4b) after {C.__name__} is defined")

print("(5a)")


@log_start_end
def main():
    func1()

    c = C()
    c.hello(name="zzz")


print(f"(5b) after {main.__name__} is defined")


if __name__ == "__main__":
    main()

print(f"(5) after {main.__name__} is called")
```

In this program, the decorator `log_start_end` decorates three functions:
* A regular function `func1`.
* A class instance method `hello`.
* The `main` function (which is actually also a regular function).

When running it in Python 3, I got the following output:

```
(1) running module ./when-called.py
(2a)
(2b) after log_start_end is defined
(3a)
starting decorator log_start_end decorating func1...
returning decorator log_start_end decorating func1...
(3b) after func1 is defined
(4a)
starting decorator log_start_end decorating hello...
returning decorator log_start_end decorating hello...
(4b) after C is defined
(5a)
starting decorator log_start_end decorating main...
returning decorator log_start_end decorating main...
(5b) after main is defined
calling main...
calling func1...
func1
returned from func1
calling hello...
hello, zzz
returned from hello
returned from main
(5) after main is called
```

According to the output, we can tell that the decorator is called when the functions and classes are defined. When the `main` function is called, all the functions/methods are fully decorated.
