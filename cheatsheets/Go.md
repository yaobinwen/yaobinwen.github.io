# Go Programming Language

## 1. References

- [1] [Golang](https://golang.org/)
- [2] [The Go Programming Language](https://www.gopl.io/)

## 2. Rules of Thumb

### 2.1 Garbage Collection

See [2] Section 5.3:

> Go's garbage collector recycles **unused memory**, but do no assume it will release unused operating system resources like open files and network connections. They should be clos ed explicitly.

### 2.2 Error Handling

See [2] Section 5.4.1:

> Because error messages are frequently chained together, **message strings should not be capitalized and newlines should be avoided**. The resulting errors may be long, but they will be self-contained when found by tools like `grep`.
>
> When designing error messages, be **deliberate**, so that each one is a meaningful description of the problem with sufficient and relevant detail, and be **consistent**, so that errors returned by the same function or by a group of functions in the same package are similar in form and can be dealt wit h in the same way.
>
> In general, **the call `f(x)` is responsible for reporting the attempted operation `f` and the argument value `x` as they relate to the context of
>
> For errors that represent transient or unpredictable problems, it may make sense to re try the failed operation, possibly with a delay between tries, and perhaps with a limit on the number of attempts or the time spent trying before giving up entirely.
>
> ... if progress is impossible, the caller can print the error and stop the program gracefully, but this course of action should generally be reserved for the main package of a program. Library functions should usually propagate errors to the caller, unless the error is a sign of an internal inconsistency - that is, a bug.
>
> ... in som e cases, it's sufficient just to log the error and then continue, perhaps with reduced functionality.
>
> in rare cases we can safely ignore an error entirely.
>
> Get into the habit of considering errors after every function call, and when you deliberately ignore one, document your intention clearly.

### 2.3 `int` vs `uint`

See [2] Section 3.1:

> Although Go provides unsigned numbers and arithmetic, we tend to use the signed `int` form even for quantities that can't be negative, such as the length of an array, though `uint` might seem a more obvious choice. Indeed, the built-in `len` function returns a signed `int`, ...
>
> ... unsigned numbers tend to be used only when their bit w ise operators or peculiar arithmetic operators are required, as when implementing bit sets, parsing binary file formats, or for hashing and cryptography.

### 2.4 Conversions

See [2] Section 3.1:

> Float to integer conversion discards any fractional part, truncating toward zero. You should avoid conversions in which the operand is out of range for the target type, because the behavior depends on the implementation.

### 2.5 Booleans

See [2] Section 3.4:

> There is no implicit conversion from a boolean value to a numeric value like 0 or 1, or vice versa.

### 2.6 Strings

See [2] Section 3.5:

> The built-in `len` function returns the number of **bytes** (not runes) in a string , and the index operation `s[i]` retrieves the _i-th_ byte of string `s`, where 0 ≤ `i` < `len(s)`.
>
> Strings may be compared with comparison operators like `==` and `<`; the comparison is done **byte by byte**, so the result is the natural lexicographic ordering.
>
> Go source files are **always** encoded in UTF-8 and Go text strings are **conventionally** interpreted as UTF-8, we can include Unicode code points in string literals.

A raw string is quoted by the back-quotes "`...`".
- No escape sequences are processed.
- The contents are taken literally, including backslashes and newlines.
  - Good for multi-line strings.
- The **only processing** is that carriage returns are deleted so that the value of the string is the same on all platforms, including those that conventionally put carriage returns in text files.

### 2.7 Constants

See [2] Section 3.6.2:

> By deferring this commitment, untyped constants not only retain their higher precision until later, but they can participate in many more expressions than committed constants without requiring conversions.

### 2.8 Arrays

Go passes in arrays as copy rather than as pointers or references. As [2] Section 4.1 says:

> When a function is called, a copy of each argument value is assigned to the corresponding parameter variable, so the function receives a copy, not the original. Passing large arrays in this way can be inefficient, and any changes that the function makes to array elements affect only the copy, not the original. In this regard, Go treats arrays like any other type, but this behavior is different from languages that implicitly pass arrays by reference. [*]

Note [*]: The last sentence "In this regard, ... by reference" means:
- Go treats arrays like any other type in Go: pass by copy.
- This pass-by-copy behavior on arrays is different from many other languages (such as C/C++) in which arrays are passed by reference.

### 2.9 Slices

See [2] Section 4.2:

> Unlike arrays, slices are not comparable, so we cannot use `==` to test whether two slices contain the same elements.
>
> The only legal slice comparison is against `nil` , as in `if summer == nil { /* ... */ }`.

See [2] Section 4.2.1:

> Usually we don't know whether a given call to `append` will cause a reallocation, so we can't assume that the original slice refers to the same array as the resulting slice, nor that it refers to a different one. Similarly, we must not assume that operations on elements of the old slice will (or will not) be reflected in the new slice. As a result, it's usual to assign the result of a call to append to the same slice variable whose value we passed to `append`: `runes = append(runes, r)`

### 2.10 Functions

Recursion won't cause stack overflow, as [2] Section 5.2 says:

> In contrast, typical Go implementations use variable-size stacks that start small and grow as needed up to a limit on the order of a gigabyte. This lets us use recursion safely and without worrying about overflow.

See [2] Section 5.7:

> Although the `...int` parameter behaves like a slice within the function body, the type of a variadic function is distinct from the type of a function with an ordinary slice parameter.

See [2] Section 5.8:

> Because deferred functions aren;t executed until the **very end of a function's execution**, a `defer` statement in a loop deserves extra scrutiny. ...
>
> One solution is to move the loop body, including the defer statement, into another function that is called on each iteration.

See [2] Section 5.9:

> Unless you can provide a more informative error message or detect an error sooner, there is no point asserting a condition that the runtime will check for you.
>
> ```go
> func Reset(x *Buffer) {
>   if x == nil {
>     panic("x is nil") // unnecessary!
>   }
>   x.elements = nil
> }
> ```
>
> In a robust program, "expected" errors, the kind that arise from incorrect input, misconfiguration, or failing I/O, should be handled gracefully; they are best dealt with using error values.

See [2] Section 5.10:

> Recovering indiscriminately from panics is a dubious practice because the state of a package's variables after a panic is rarely well defined or documented. Perhaps a critical update to a data structure was incomplete, a file or network connection was opened but not closed, or a lock was acquired but not released. Furthermore, by replacing a crash with, say, a line in a log file, indiscriminate recovery may cause bugs to go unnoticed.
>
> Recovering from a panic within the same package can help simplify the handling of complex or unexpected errors, but as a general rule, you should not attempt to recover from another package's panic. Public APIs should report failures as errors. Similarly, you should not recover from a panic that may pass through a function you do not maintain, such as a caller-provided callback, since you cannot reason about its safety.

#### 2.10.1 Capturing Iteration Variables

See [2] Section 5.6.1:

> All function values created by this loop "capture" and share the same variable - an addressable storage location, not its value at that particular moment.
