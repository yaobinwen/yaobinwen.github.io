---
comments: true
date: 2024-01-26
layout: post
tags: [Tech,Python]
title: On GIL and thread safety in Python
---

> Python has the [Global Interpreter Lock](https://wiki.python.org/moin/GlobalInterpreterLock), why should I still care about thread safety?

## Introduction

If you read articles about _Global Interpreter Lock (GIL)_ such as [1] and [2], you will see explanations like these:

> In CPython, the global interpreter lock, or GIL, is a mutex that protects access to Python objects, preventing multiple threads from executing Python bytecodes at once.  The GIL prevents race conditions and ensures thread safety. ... In short, this mutex is necessary mainly because CPython's memory management is not thread-safe.

and

> The Python Global Interpreter Lock or GIL, in simple words, is a mutex (or a lock) that allows only one thread to hold the control of the Python interpreter.
>
> This means that only one thread can be in a state of execution at any point in time.

That sounds like Python doesn't have any thread safety issues to worry about, but that's the confusion. You still need to worry about the thread safety in **your Python program**. GIL only guarantees the thread safety inside the **Python interpreter**, and your Python program and the Python interpreter that executes the program are two different things.

To fully discuss this topic, I will need to discuss the sub-topics in the following sections. I will focus on [CPython](https://github.com/python/cpython) because, to be honest, I've only worked with CPython so far.

## The three parts in a Python process

When you run your Python program, an operating system process is launched. This Python process roughly includes three parts:
- 1). One Python interpreter.
- 2). The GIL.
- 3). One or more Python threads.

Here is a side note about the number of Python interpreters in a Python process. Since Python 1.5, a Python process can create multiple Python interpreters via its C APIs: one being the primary interpreter and the others being the "subinterpreters". However, in the early Python versions, all the interpreters still shared the same GIL, so the multi-interpreter structure still couldn't make the best use of true parallelism. This situation has been improved significantly in the recent years by [PEP 554](https://peps.python.org/pep-0554/) and [PEP 684](https://peps.python.org/pep-0684/). The subinterpreters as a Python standard library is anticipated in Python 3.13. But in this article, we mainly focus on the case of a single interpreter.

When a Python process is launched, we know it at least has the main thread. If we use the [threading](https://docs.python.org/3/library/threading.html) module, we can start more threads. Because the entire program is written in Python, the code in every thread is of course in Python as well. Therefore, we will need to use the Python interpreter to execute the code in the threads.

When it comes to multi-threading programming, we always need to consider the issues of [race conditions](https://en.wikipedia.org/wiki/Race_condition) and [deadlocks](https://en.wikipedia.org/wiki/Deadlock).

## Reference counting

CPython's primary garbage collection algorithm is [reference counting](https://en.wikipedia.org/wiki/Reference_counting). As depicted in [3], the internal C structure of a regular Python object looks as follows:

```
object -----> +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+ \
              |                    ob_refcnt                  | |
              +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+ | PyObject_HEAD
              |                    *ob_type                   | |
              +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+ /
              |                      ...                      |
```

In CPython 3.12 source code, they are defined in [`Include/object.h`](https://github.com/python/cpython/blob/3.12/Include/object.h) as follows:

```c
struct _object {
    _PyObject_HEAD_EXTRA

    /* ... other auxiliary code ... */

    union {
       Py_ssize_t ob_refcnt;
#if SIZEOF_VOID_P > 4
       PY_UINT32_T ob_refcnt_split[2];
#endif
    };

    /* ... other auxiliary code ... */

    PyTypeObject *ob_type;
};
```

The correct working of Python's garbage collection thus relies on the correct working of the reference counting which then relies on the fact that reference counts are incremented/decremented correctly. In the previous section, we know that a Python process may contain multiple threads and, if not handled appropriately, the multiple threads can cause race conditions that produce undetermined results when modifying variables' values. Therefore, we need a synchronization mechanism, usually some kind of lock, to synchronize the execution of threads so they can modify the reference counts in an appropriate order to produce the correct values.

## The GIL

To prevent the race condition when updating the reference counts of objects, we can add one lock for every object. However, a Python program may use many objects thus need many locks. These many locks can result in other side-effects:
- Deadlocks
- Decreased performance that's caused by repeated acquisition and release of the locks.

CPython's solution is the use of a single GIL: When a thread wants to use the Python interpreter to execute the Python code of this thread, it must firstly obtain the GIL. Because GIL is mutually exclusively, as a result, no two threads can use the Python interpreter at the same time. GIL solves the race conditions and deadlocks in the following way:
- 1). Because GIL forces the threads to take turns to run, in other words, at any certain point of time, there is guaranteed to be exactly one thread running, so there is no way for race conditions to occur in the first place.
- 2). Because there is only one GIL, there is no way for deadlocks to happen because deadlocks always involve more than one lock.

## Thread safety

We can thus tell that, according to the sections above, what GIL really protects from multi-threading issues is the internal state (e.g., the objects' reference counts) of the Python interpreter. Your code may still suffer from race conditions in the multi-threading context. Take the following code for example:

```python
#!/usr/bin/python3
# File name: race-condition.py

import sys
import threading


N = int(sys.argv[1])
A = 0


def inc_A(N, inc):
    global A
    for i in range(0, N):
        A += inc


def main(N):
    t1 = threading.Thread(target=inc_A, args=(N, 1,))
    t2 = threading.Thread(target=inc_A, args=(N, -1,))

    t1.start()
    t2.start()

    t1.join()
    t2.join()

    print(f"A = {A}")


if __name__ == "__main__":
    main(int(sys.argv[1]))

```

Because we increment the global variable `A` N times and decrement it N times as well, ideally, the result of `A` should remain `0`. However, on my computer, when I made `N` a kind of big number, the result value of `A` was not deterministic:

```
$ ./race-condition.py 300000
A = 219600
$ ./race-condition.py 300000
A = 0
$ ./race-condition.py 300000
A = -118077
```

If the race condition doesn't happen on your computer, try to make the input `N` value larger.

As we discussed in the earlier sections, GIL prevents the corruption of the Python interpreter's internal state (e.g., the reference counts). Therefore, when executing the example Python code above, GIL could guarantee that the reference counts of the following variables were all updated correctly:
- `N`
- `A`
- `t1`
- `t2`

However, the ideal result of `A` being `0` also relies on the assumption that the statement `A += inc` is executed atomically, but this is beyond GIL's protection scope, so race conditions could still occur.

Let's analyze it deeper. The statement `A += inc` can be broken into three smaller steps (and let's assume they are atomic):
- Retrieve the current value of `A`: `a <- A`.
- Add the current value with `inc`: `a <- a + inc`
- Write the new value back to `A`: `A <- a`

If `t1` and `t2` are well synchronized, the two threads will not switch execution before all the three steps are finished. However, without proper synchronization, the following execution sequence, as just one possibility, could happen:

| t1           | t2           | A  |
|:------------:|:------------:|:--:|
| (idle)       | (idle)       | 0  |
| `a <- A`     | (idle)       | 0  |
| `a <- a + 1` | (idle)       | 0  |
| (idle)       | `a <- A`     | 0  |
| (idle)       | `a <- a - 1` | 0  |
| `A <- a`     | (idle)       | 1  |
| (idle)       | `A <- a`     | -1 |
| (idle)       | (idle)       | -1 |

As a result, the final value of `A` was not `0` but `-1`. If this sequence happened `118077` times, you would see the `A = -118077` as I saw when I ran the example code above.

## The fix

To fix the race condition, we only need to add a lock `L` to protect the critical section (i.e., the statement `A += inc`):

```python
# ...

L = threading.Lock()  # A lock that protects A.
A = 0


def inc_A(N, inc):
    global L
    global A
    for i in range(0, N):
        # Lock the critical section to prevent thread preemption.
        with L:
          A += inc

# ...
```

It definitely runs much slower than before due to the lock, but now it can always produce the correct result:

```
$ ./race-condition.py 300000
A = 0
$ ./race-condition.py 300000
A = 0
$ ./race-condition.py 300000
A = 0
```

## Further readings

- [Running Python Parallel Applications with Sub Interpreters](https://tonybaloney.github.io/posts/sub-interpreter-web-workers.html)
- [On the notion of what it means to be "thread safe"](https://discuss.python.org/t/on-the-notion-of-what-it-means-to-be-thread-safe/28605)
- [Understanding the Python GIL](https://www.youtube.com/watch?v=Obt-vMVdM8s)

## References

- [1] [Python WiKi: Global Interpreter Lock](https://wiki.python.org/moin/GlobalInterpreterLock)
- [2] [RealPython: What Is the Python Global Interpreter Lock (GIL)?](https://realpython.com/python-gil/)
- [3] [Python Developer's Guide: Garbage collector design](https://devguide.python.org/internals/garbage-collector/index.html)
