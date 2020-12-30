---
comments: true
date: 2017-02-21
layout: post
tags: [Tech]
title: Understanding Python BNF Notation
---

The Python 2 documentation uses a modified [BNF](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form) grammar notation which is detailed in [1.2. Notation](https://docs.python.org/2/reference/introduction.html#notation).

Although it is described as a _modified_ version of BNF, I personally think it is more like a mixture of BNF and regular expressions. In the remaining part of this article, I will address this modified BNF as **Python BNF**.

The Python BNF, in general, follows the form of the standard BNF that each statement is written as follows:

```bnf
symbol ::= expression
```

If the **expression** may have alternative forms, they are divided by the vertical bar "|".

For example, the grammar token for a _letter_ in Python is defined [here](https://docs.python.org/2/reference/lexical_analysis.html#grammar-token-letter):

```bnf
letter     ::=  lowercase | uppercase
lowercase  ::=  "a"..."z"
uppercase  ::=  "A"..."Z"
```

The definition shows that a _letter_ is **either** a _lowercase_ **or** an _uppercase_ character, and the _lowercase_ and _uppercase_ are subsequently defined in the next two lines.

These two symbols, the ```::=``` and ```|```, are probably the only elements Python BNF inherits from the standard BNF.

The **expression** is defined more like an regular expression. [The document](https://docs.python.org/2/reference/introduction.html#notation) lists the other supported expressions:

* A star (\*) means the zero or more repetitions of the preceding item.
* A plus (+) means one or more repetitions.
* A phrase enclosed in square brackets ([ ]) means zero or one occurrences (in other words, the enclosed phrase is optional).
* Parentheses are used for grouping.
* Literal strings are enclosed in quotes.
* Two literal characters separated by three dots mean a choice of any single character in the given (inclusive) range of ASCII characters.
*  A phrase between angular brackets (<...>) gives an informal description of the symbol defined.

We can look at some examples.

The [identifier](https://docs.python.org/2/reference/lexical_analysis.html#grammar-token-identifier) is defined as follows:

```bnf
identifier ::= (letter|"_") (letter | digit | "_")*
```

This expression can be interpreted as below:

* An identifier consists of two parts: The first part is a _letter_ or an underscore, as specified in ```(letter|"_")```; the second part is optional because it is followed by a star(\*).
* Because the first part doesn't contain a _digit_, this means a valid identifier does not start with a digit.

We can look at a more complex example, the [string literals](https://docs.python.org/2/reference/lexical_analysis.html#string-literals):

```bnf
stringliteral   ::=  [stringprefix](shortstring | longstring)
stringprefix    ::=  "r" | "u" | "ur" | "R" | "U" | "UR" | "Ur" | "uR"
                     | "b" | "B" | "br" | "Br" | "bR" | "BR"
shortstring     ::=  "'" shortstringitem* "'" | '"' shortstringitem* '"'
longstring      ::=  "'''" longstringitem* "'''"
                     | '"""' longstringitem* '"""'
shortstringitem ::=  shortstringchar | escapeseq
longstringitem  ::=  longstringchar | escapeseq
shortstringchar ::=  <any source character except "\" or newline or the quote>
longstringchar  ::=  <any source character except "\">
escapeseq       ::=  "\" <any ASCII character>
```

The interpretation goes as follows:

* A string literal consists of two parts: The first part is a _stringprefix_ which is optional because it is enclosed in square brackets; the second part is either a _shortstring_ or a _longstring_.
* A _stringprefix_ is one of all the listed prefixes. This one is easy to understand.
* A _shortstring_ has two forms. In the first form, the _shortstringitems_ are enclosed in a pair of single quotation marks, while in the second form, they are enclosed in a pair of double quotation marks.
* A _longstring_ is different from a _shortstring_ in two aspects: The first aspect is that a _longstring_ is enclosed in a pair of triple quotation marks; the second aspect is that a _longstring_ can contain newline or the quote characters.
