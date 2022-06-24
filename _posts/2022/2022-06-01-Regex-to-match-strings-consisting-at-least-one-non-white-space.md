---
comments: true
date: 2022-06-01
layout: post
tags: [Tech,Regex]
title: The regular expression that matches strings of certain length that consist of at least one non-whitespace character
---

The system I'm working on has an input field that we use **exactly one regular expression** to test if the given value is valid or not. The validity tests are:
- 1). It can't be an empty string, i.e., the length must be greater than zero.
- 2). The string consists of at most 10 characters.
- 3). At least one character must be a non-whitespace character.

For example, the following values are acceptable (note that `\w` refers to a whitespace which is either a blank space or a tab):

| Value | Acceptable? | Notes |
|:-----:|:-----------:|:------|
| `"0123"` | Yes | Less than 10 characters. |
| `"0123456789"` | Yes | Exactly 10 characters. |
| `"0123456789abc"` | No | Longer than 10 characters. |
| `"\w\w\w"` | No | Only white spaces |
| `"A\w\w\w\w\w\w"` | Yes | A lot of white spaces but has at least an non-whitespace character `A`. |
| `"\w\w\w\wA"` | Yes | A lot of white spaces but has at least an non-whitespace character `A`. |
| `"\w\w\wA\w\w\w"` | Yes | A lot of white spaces but has at least an non-whitespace character `A`. |

The first regular expression that bumped into my head was `^.*\S.*$` which means:
- `\S`: There must be one non-whitespace character.
- `.*` before `\S`: There can be an arbitrary number of any characters before the non-whitespace character.
- `.*` after `\S`: There can be an arbitrary number of any characters after the non-whitespace character.

This regular expression can satisfy the validity tests 1) and 3). Unfortunately, it doesn't limit the string length to 10 at most. As a result, the string `01234567890123456789` will also pass the validity test.

[This answer](https://stackoverflow.com/a/3085553/630364) that uses **negative lookahead** inspired and helped me figure out the solution to my problem: `^(?!\s*$).{1,10}$`. You can try this regular expression to any one of the following online regular expression testing websites:
- [https://regexr.com/](https://regexr.com/)
- [regular expressions 101](https://regex101.com/)
- [RegEx Testing](https://www.regextester.com/)

Using negative lookbehind `^(?<!\s*$).{1,10}$` may not work because the `*` quantifier inside a lookbehind makes it non-fixed width, but, as mentioned in [_Lookahead and Lookbehind Zero-Length Assertions_](https://www.regular-expressions.info/lookaround.html), many regular expression implementations "including those used by Perl, Python, and Boost only allow **fixed-length** strings."
