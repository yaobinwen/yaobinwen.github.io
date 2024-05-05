---
comments: true
date: 2024-05-05
layout: post
tags: [Tech, C++]
title: Stack unwinding and destructors that throw exceptions (in C++)
---

Frankly speaking, I only have the experience in explicitly thinking about stack unwinding when I program in C++. Although I think stack unwinding is probably a feature of any programming language (e.g., C#, Java, Python) that supports exception handling or error propagation mechanisms, I don't have the hands-on experience of dealing with stack unwinding in those programming languages so I'll focus on the C++ examples in this article.

## Recap of stack unwinding

When an exception is thrown, the execution control moves from the `throw` site to the first `catch` clause that can handle the type of the thrown exception. The exception propagates to the caller hierarchy until the first `catch` that can handle the exception is found. For example, in the following C++ code:

```c++
class E1 {};  // Exception type 1
class E2 {};  // Exception type 2

class A {};

void f1(int n)
{
  try
  {
    A a1;

    f2(n);

    A a6;
  }
  catch (E1 e1)
  {
    // Handle E1
  }
}

void f2(int n)
{
  try
  {
    A a2;

    if (n < 0)
    {
      A a3;

      // Will be handled by the `catch` in this function.
      throw E2();
    }
    else if (n > 0)
    {
      A a4;

      // Will be handled by the `catch` in the caller function `f1`.
      throw E1();
    }

    A a5;
  }
  catch (E2 const &e2)
  {
    // Handle E2
  }
}
```

When the given value of `n` is less than zero, an exception of type `E2` is thrown and it will be caught by the `catch (E2 const &e2)` handler in `f2`; if the given value of `n` is greather than zero, an exception of type `E1` is thrown, but because none of the `catch` handlers in `f2` can handle `E1`, the exception is propagated to `f2`'s caller `f1` and is handled by the `catch (E1 e1)` handler there.

When an appropriate `catch` handler is found, the parameter in the `catch` specification is initialized. In the example code above, the parameters are `e1` and `e2`. `catch (E1 e1)` receives a copy of the thrown `E1` exception, so `e1` is initialized by calling `E1`'s copy constructor; `catch (E2 const &e2)` receives a (constant) reference to the thrown `E2` exception, so `e2` is initialized without calling `E2`'s copy constructor.

The stack unwinding process begins after the `catch` handler's parameter is initialized. The stack unwinding process involves the destruction of all the **automatic** objects that have been **fully** constructed but not yet destructed between the beginning of the `try` section that the `catch` handler is associated with, and line of `throw`.

In the example code above:
- If `E2` is thrown, the `catch (E2 const &e2)` handler is called to handle the exception. Because the `try` section that's associated with this `catch` handler is in `f2`, stack unwinding happens inside `f2` only, and stack unwinding will destruct `a3` and `a2` because they are automatic objects and have been fully constructed since the beginning of the `try` section and the `throw E2()` statement.
  - Once the exception `e2` is handled in `f2`, the execution control returns `f1`. Eventually, `a1` and `a6` will also be destructed but they are not destructed by the stack unwinding because `f2` has fully handled the exception `e2` so `f1`'s exception handling is not called at all, hence no stack unwinding.
- If `E1` is thrown, the `catch (E1 e1)` handler is called to handle the exception. Because the `try` section that's associated with this `catch` handler is in `f1`, stack unwinding happens covers the beginning of the `try` section in `f1` all the way to the `throw E1()` statement in `f2`. Therefore, `a4`, `a2`, and `a1` are destructed during stack unwinding. In this case, none of `a3`, `a5`, and `a6` were constructed so they were not destructed.

## Exceptions during stack unwinding

If an exception is thrown **during** stack unwinding, the [`terminate` handler](https://en.cppreference.com/w/cpp/error/terminate_handler) is called and, usually, the C++ program is aborted. According to the previous section, we can see there are two cases in which an exception can be thrown during stack unwinding:
- If the copy constructor of the exception object throws an exception.
- If the destructor of an automatic object throws an exception.

By default, the copy constructor and the destructor of a class is treated to be non-throwing (i.e., `noexcept(true)`). See ["cppreference: Copy constructors"](https://en.cppreference.com/w/cpp/language/copy_constructor) and ["cppreference: Destructors"](https://en.cppreference.com/w/cpp/language/destructor), which both refers to ["cppreference: noexcept specifier"](https://en.cppreference.com/w/cpp/language/noexcept_spec). The developers can surely declare them as "potentially-throwing" ones if throwing an exception makes sense in the context. But the fact that they are treated as non-throwing functions by default shows that the C++ language really hopes that the developers can make their best effort to make sure the copy constructor and the destructor do not throw.

The section "Item 8: Prevent exceptions from leaving destructors" in _Effective C++_ (3rd edition) discusses why this should be done and gives concreate suggestions of how to achieve this goal.

## More examples

See [Stack-Unwinding/Demo](https://github.com/yaobinwen/designing-and-implementing/tree/main/Stack-Unwinding/Demo) for the demo code.

## References

- [Learn Microsoft: Exceptions and Stack Unwinding in C++](https://learn.microsoft.com/en-us/cpp/cpp/exceptions-and-stack-unwinding-in-cpp?view=msvc-170)
