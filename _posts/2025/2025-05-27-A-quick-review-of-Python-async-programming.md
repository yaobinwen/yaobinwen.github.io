---
comments: true
date: 2025-05-27
layout: post
tags: [Tech,Async,Python]
title: "A Quick Review of Python Async Programming"
---

This article uses the `asyncio` documentation of Python 3.12. This article doesn't cover everythig about the `asyncio` module but only covers the parts that I use regularly.

## Concepts

An [event loop](https://docs.python.org/3.12/library/asyncio-eventloop.html#event-loop) is the core of the `asyncio` programs.

> Event loops run asynchronous tasks and callbacks, perform network IO operations, and run subprocesses.
>
> Application developers should typically use the high-level `asyncio` functions, such as `asyncio.run()`, and should rarely need to reference the loop object or call its methods.

A [coroutine](https://docs.python.org/3.12/library/asyncio-task.html#coroutines) is an object that an `async` function returns.
- Technically, this `async` function itself is called a ["coroutine function"](https://docs.python.org/3.12/glossary.html#term-coroutine-function) but itself is **NOT** a coroutine. In reality, "coroutine" and "coroutine function" are often used interchangeably.
- I think the "co" part in the name "coroutine" means "cooperative" because the coroutines cooperate with each other (by yielding the execution back to the even loop to allow other coroutines to progress forward) to finish the work.
- In some aspects, a coroutine and a generator (which uses `yield` to give the execution back to the caller) are similar:
  - They can both be entered, returned (or exited), and resumed at many different points and many times.
    - Inside a coroutine, every `await` call to other coroutines are the points that the current coroutine gives the execution back to the even loop. Later the execution of this current coroutine can resume from the point after this `await`.
    - Inside a generator, every `yield` call gives the execution back to the caller. Later the execution of this current generator can resume from the point after this `yield`.
  - They are both cooperative code:
    - When a coroutine runs into an `await`, it gives the execution back to the event loop so the event loop can executes other coroutines.
    - When a generator runs into an `yield`, it gives the execution back to the caller so the caller can run other code (could be other generators).

Note that calling a coroutine function **only creates a coroutine but does not execute it** until `await` is used (or `asyncio.run` is used).

A [Task](https://docs.python.org/3.12/library/asyncio-task.html#asyncio.Task) is a scheduled concurrent execution (i.e., non-blocking execution) of a coroutine, and a task is a **future-like object**.

A [Future](https://docs.python.org/3.12/library/asyncio-future.html) is considered a low-level awaitable object and normally there is no need to create a Future object in the application-level code.

## How to run a coroutine

In Python 3.7+, [`asyncio.run`](https://docs.python.org/3.12/library/asyncio-runner.html#asyncio.run) is recommended for running a coroutine because it is simple:

> This function runs the passed coroutine, taking care of managing the asyncio event loop, finalizing asynchronous generators, and closing the executor.

Note that `asyncio.run` only accepts a coroutine but not a Task. If given a Task, `asyncio.run` throws `ValueError` with the message "a coroutine was expected". This can be seen in the source code:

```python
def run(main, *, debug=None, loop_factory=None):
    """Execute the coroutine and return the result.

    This function runs the passed coroutine, taking care of
    managing the asyncio event loop, finalizing asynchronous
    generators and closing the default executor.

    This function cannot be called when another asyncio event loop is
    running in the same thread.

    If debug is True, the event loop will be run in debug mode.

    This function always creates a new event loop and closes it at the end.
    It should be used as a main entry point for asyncio programs, and should
    ideally only be called once.

    The executor is given a timeout duration of 5 minutes to shutdown.
    If the executor hasn't finished within that duration, a warning is
    emitted and the executor is closed.

    Example:

        async def main():
            await asyncio.sleep(1)
            print('hello')

        asyncio.run(main())
    """
    if events._get_running_loop() is not None:
        # fail fast with short traceback
        raise RuntimeError(
            "asyncio.run() cannot be called from a running event loop")

    with Runner(debug=debug, loop_factory=loop_factory) as runner:
        return runner.run(main)
```

where `runner.run` does the following:

```python
class Runner:
    # ... (other code)

    def run(self, coro, *, context=None):
        """Run a coroutine inside the embedded event loop."""
        if not coroutines.iscoroutine(coro):
            raise ValueError("a coroutine was expected, got {!r}".format(coro))

        # ... (other code)
```

## How to run a Task

A coroutine can be wrapped into a Task by calling `asyncio.create_task` or `event_loop.create_task`. But because an **running** event loop is needed in order to create a Task, you need to call these two functions in different situations.

`asyncio.create_task` can only be used when a **running** event loop has already been created. In Python 3.7+, a running event loop is created when `asyncio.run` is called. Therefore, you can call `asyncio.create_task` in the coroutine function that's passed to `asyncio.run`. See the example code in the section ["Awaitables"](https://docs.python.org/3.12/library/asyncio-task.html#awaitables):

```python
import asyncio

async def nested():
    return 42

async def main():
    # Schedule nested() to run soon concurrently
    # with "main()".
    task = asyncio.create_task(nested())

    # "task" can now be used to cancel "nested()", or
    # can simply be awaited to wait until it is complete:
    await task

asyncio.run(main())
```

In this example, `main` is a coroutine function. When `asyncio.run(main())` runs, a running event loop is created by `asyncio.run`. Therefore, we can call `asyncio.create_task` inside `main` because at this point, a running event loop is available.

In contrast, if you have never created a running event loop, calling `asyncio.create_task` will throw "RuntimeError: no running event loop". For example:

```python
import asyncio

async def work():
    print("hello!")
    await asyncio.sleep(1)
    print("world!")

t = asyncio.create_task(work())
```

The first workaround is surely to call an `async` function using `asyncio.run` and then call `asyncio.create_task` inside this `async` function. Another workaround is manually creating a running event loop and call `event_loop.create_task` (see the code below), but this is generally not encouranged:

```python
import asyncio

async def work():
    print("hello!")
    await asyncio.sleep(1)
    print("world!")

event_loop = asyncio.new_event_loop()
asyncio.set_event_loop(event_loop)
t = event_loop.create_task(work())
event_loop.run_until_complete(t)
```

## DeprecationWarning: There is no current event loop

In earlier versions of Python (e.g., 3.6), you can create a new event loop at the beginning of the program by simply calling `asyncio.get_event_loop()` because it will automatically create a new event loop if there is none (see the line `self.set_event_loop(self.new_event_loop())`):

```python
def get_event_loop():
    """Return an asyncio event loop.

    When called from a coroutine or a callback (e.g. scheduled with call_soon
    or similar API), this function will always return the running event loop.

    If there is no running event loop set, the function will return
    the result of `get_event_loop_policy().get_event_loop()` call.
    """
    current_loop = _get_running_loop()
    if current_loop is not None:
        return current_loop
    return get_event_loop_policy().get_event_loop()

class BaseDefaultEventLoopPolicy(AbstractEventLoopPolicy):
    """Default policy implementation for accessing the event loop.

    In this policy, each thread has its own event loop.  However, we
    only automatically create an event loop by default for the main
    thread; other threads by default have no event loop.

    Other policies may have different rules (e.g. a single global
    event loop, or automatically creating an event loop per thread, or
    using some other notion of context to which an event loop is
    associated).
    """

    _loop_factory = None

    class _Local(threading.local):
        _loop = None
        _set_called = False

    def __init__(self):
        self._local = self._Local()

    def get_event_loop(self):
        """Get the event loop.

        This may be None or an instance of EventLoop.
        """
        if (self._local._loop is None and
            not self._local._set_called and
            isinstance(threading.current_thread(), threading._MainThread)):
            self.set_event_loop(self.new_event_loop())
        if self._local._loop is None:
            raise RuntimeError('There is no current event loop in thread %r.'
                               % threading.current_thread().name)
        return self._local._loop
```

However, in newer versions of Python, [`asyncio.get_event_loop()`](https://docs.python.org/3.12/library/asyncio-eventloop.html#asyncio.get_event_loop) effectively means "get the running event loop" because:

> ... this function will always return the running event loop.

As a result, since Python 3.12, `asyncio.get_event_loop()` is supposed to only be called when there is already a running loop. If no running loop has been created, it still creates a new event loop (see the line `self.set_event_loop(self.new_event_loop())`) but also raises `DeprecationWarning` with the message "There is no current event loop" (see the line `warnings.warn(...)`):

```python
    def get_event_loop(self):
        """Get the event loop for the current context.

        Returns an instance of EventLoop or raises an exception.
        """
        if (self._local._loop is None and
                not self._local._set_called and
                threading.current_thread() is threading.main_thread()):
            stacklevel = 2
            try:
                f = sys._getframe(1)
            except AttributeError:
                pass
            else:
                # Move up the call stack so that the warning is attached
                # to the line outside asyncio itself.
                while f:
                    module = f.f_globals.get('__name__')
                    if not (module == 'asyncio' or module.startswith('asyncio.')):
                        break
                    f = f.f_back
                    stacklevel += 1
            import warnings
            warnings.warn('There is no current event loop',
                          DeprecationWarning, stacklevel=stacklevel)
            self.set_event_loop(self.new_event_loop())

        if self._local._loop is None:
            raise RuntimeError('There is no current event loop in thread %r.'
                               % threading.current_thread().name)

        return self._local._loop
```

And the documentation says "In some future Python release this will become an error." That means in the future Python versions, we must call this function only when there is a running event loop.
