# Go Programming Language

## References

- [1] [Golang](https://golang.org/)
- [2] [The Go Programming Language](https://www.gopl.io/)

## Rules of Thumb

### `int` vs `uint`

See [2] Section 3.1:

> Although Go provides unsigned numbers and arithmetic, we tend to use the signed `int` form even for quantities that can't be negative, such as the length of an array, though `uint` might seem a more obvious choice. Indeed, the built-in `len` function returns a signed `int`, ...
>
> ... unsigned numbers tend to be used only when their bit w ise operators or peculiar arithmetic operators are required, as when implementing bit sets, parsing binary file formats, or for hashing and cryptography.

### Conversions

See [2] Section 3.1:

> Float to integer conversion discards any fractional part, truncating toward zero. You should avoid conversions in which the operand is out of range for the target type, because the behavior depends on the implementation.

### Booleans

See [2] Section 3.4:

> There is no implicit conversion from a boolean value to a numeric value like 0 or 1, or vice versa.

### Strings

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

### Constants

See [2] Section 3.6.2:

> By deferring this commitment, untyped constants not only retain their higher precision until later, but they can participate in many more expressions than committed constants without requiring conversions.

### Arrays

Go passes in arrays as copy rather than as pointers or references. As [2] Section 4.1 says:

> When a function is called, a copy of each argument value is assigned to the corresponding parameter variable, so the function receives a copy, not the original. Passing large arrays in this way can be inefficient, and any changes that the function makes to array elements affect only the copy, not the original. In this regard, Go treats arrays like any other type, but this behavior is different from languages that implicitly pass arrays by reference. [*]

Note [*]: The last sentence "In this regard, ... by reference" means:
- Go treats arrays like any other type in Go: pass by copy.
- This pass-by-copy behavior on arrays is different from many other languages (such as C/C++) in which arrays are passed by reference.

### Slices

See [2] Section 4.2:

> Unlike arrays, slices are not comparable, so we cannot use `==` to test whether two slices contain the same elements.
>
> The only legal slice comparison is against `nil` , as in `if summer == nil { /* ... */ }`.

See [2] Section 4.2.1:

> Usually we don't know whether a given call to `append` will cause a reallocation, so we can't assume that the original slice refers to the same array as the resulting slice, nor that it refers to a different one. Similarly, we must not assume that operations on elements of the old slice will (or will not) be reflected in the new slice. As a result, it's usual to assign the result of a call to append to the same slice variable whose value we passed to `append`: `runes = append(runes, r)`
