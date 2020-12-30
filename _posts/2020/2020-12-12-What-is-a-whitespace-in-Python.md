---
comments: true
date: 2020-12-12
layout: post
tags: [Tech]
title: What is a "whitespace" in Python?
---

One day I was programming and wanted to call `str.strip()` to remove the leading and trailing whitespaces as well as new line characters. I roughly remembered `str.strip()` could do it but would like to confirm. When I read its documentation [1], I was surprised that it doesn't mention "new line":

> If omitted or None, the chars argument defaults to removing `whitespace`.

At that time, my understanding of a "whitespace" was either a blank space (entered by the spacebar) or a Tab (entered by the Tab key). I was aware of the existence of a "vertical tab" (though I had rarely used it), but I still considered a "new line" to be different from a "whitespace".

I ran some simple code and found the "whitespace" that `str.strip()` dealt with included a "new line".

```python
>>> s = "  abc\n"
>>> s
'  abc\n'
>>> s.strip()
'abc'
```

So I started to wonder what exactly a "whitespace" was. This term was explained by `str.isspace()` [2]:

> A character is whitespace if in the Unicode character database (see [unicodedata](https://docs.python.org/3/library/unicodedata.html), either its general category is `Zs` ("Separator, space"), or its bidirectional class is one of `WS`, `B`, or `S`.

Things started to become interesting. It occurred to me immediately that the reference to Unicode made total sense here because in Python 3, `str` is used to deal with the text data which is the semantic representation of characters rather than their binary representation in the computer's memory. Therefore, a "whitespace" in terms of Unicode is different from the "whitespace" in ASCII. The former should be a superset of the latter.

[3] provides a good breakdown of different components in Unicode. Two of them are "Unicode Character Categories" and "Unicode Bidirectional Classes" which turn out to be two properties of a Unicode code point.

[4] explains "character categories":

> The `General_Category` property of a code point provides for the most general classification of that code point.
>
> Many characters have multiple uses, and **not all such cases can be captured entirely by the `General_Category` value**. For example, the General_Category value of Latin, Greek, or Hebrew letters does not attempt to cover (or preclude) the numerical use of such letters as Roman numerals or in other numerary systems. Conversely, the General_Category of ASCII digits 0..9 as Nd (decimal digit) neither attempts to cover (or preclude) the occasional use of these digits as letters in various orthographies. **The `General_Category` is simply the first-order, most usual categorization of a character.**

This section also lists the possible values of `General_Category`, and `Zs` is defined as "Space_Separator: a space character (of various non-zero widths)". There are also `Zl` and `Zp` but these two are not counted as "whitespace" according to [2].

[5] is the Unicode database in the form of a text file. If you `grep "Zs"` on it, you'll get:

```
0020          ; Common # Zs       SPACE
00A0          ; Common # Zs       NO-BREAK SPACE
2000..200A    ; Common # Zs  [11] EN QUAD..HAIR SPACE
202F          ; Common # Zs       NARROW NO-BREAK SPACE
205F          ; Common # Zs       MEDIUM MATHEMATICAL SPACE
3000          ; Common # Zs       IDEOGRAPHIC SPACE
1680          ; Ogham # Zs       OGHAM SPACE MARK
```

There are totally 17 `Zs` code points (`2000..200A` indicates a range, inclusive on both ends). `U+0020` (in hexidecimal) is the ASCII 32 which is the usual space entered by the spacebar.

[6] does not explain "bidirectional classes" but simply lists the available values. The three ones that `str.isspace()` cares about are:

| Abbr | Long | Description |
|:----:|:-----|:------------|
| B | Paragraph_Separator | various newline characters |
| S | Segment_Separator | various segment-related control codes |
| WS | White_Space | spaces |

These three all have the "neutral types", and [7] explains the meaning of "bidirectional" (including "neutral types"):

> The Unicode Standard prescribes a memory representation order known as logical order. When text is presented in horizontal lines, most scripts display characters from left to right. However, there are several scripts (such as Arabic or Hebrew) where the natural ordering of horizontal text in display is from right to left. If all of the text has a uniform horizontal direction, then the ordering of the display text is unambiguous.
>
> However, because these right-to-left scripts use digits that are written from left to right, the text is actually bidirectional: a mixture of right-to-left and left-to-right text. In addition to digits, embedded words from English and other scripts are also written from left to right, also producing bidirectional text. Without a clear specification, ambiguities can arise in determining the ordering of the displayed characters when the horizontal direction of the text is not uniform.
>
> ...
>
> Each character has an **implicit** _bidirectional type_. The bidirectional types left-to-right and right-to-left are called **strong types**, and characters of those types are called strong directional characters. The bidirectional types associated with numbers are called **weak types**, and characters of those types are called weak directional characters. With the exception of the directional formatting characters, the remaining bidirectional types and characters are called **neutral**. The algorithm uses the implicit bidirectional types of the characters in a text to arrive at a reasonable display ordering for text.
>
> When working with bidirectional text, the characters are still interpreted in logical order - only the display is affected. The display ordering of bidirectional text depends on the directional properties of the characters in the text. Note that there are important security issues connected with bidirectional text: for more information, see [UTR36](https://www.unicode.org/reports/tr36/).

A side note about bidirectional rendering: according to [7] (explained immediately under the section title "2 Directional Formatting Characters"), the characters are usually rendered to display using their implicit bidirectional types unless there are **explicit directional formatting characters** that change how they should be rendered.

So, come back to the "whitespace" topic. the three bidirectional classes that [2] mentions are all of neutral types which means the display direction doesn't really matter to them.

Class `B` contains the following characters [8]:

| Unicode | Character | Name |
|:-------:|:---------:|:-----|
| U+000A | LF | `<End of Line>` (EOL, LF, NL) |
| U+000D | CR | `<Carriage Return>` (CR) |
| U+001C | FS | `<File Separator>` (FS) |
| U+001D | GS | `<Group Separator>` (GS) |
| U+001E | RS | `<Information Separator Two>` (RS) |
| U+0085 | NEL | `<Next Line>` (NEL) |
| U+2029 | | Paragraph Separator |

Class `S` contains the following characters [9]:

| Unicode | Character | Name |
|:-------:|:---------:|:-----|
| U+0009 | HT | `<Character Tabulation>` (HT, TAB) |
| U+000B | VT | `<Line Tabulation>` (VT) |
| U+001F | US | `<Information Separator One>` (US) |

Class `WS` contains the following characters [10]:

| Unicode | Character | Name |
|:-------:|:---------:|:-----|
| U+000C | FF | `<Form Feed>` (FF) |
| U+0020 | SP | Space (SP) |
| U+1680 | | Ogham Space Mark |
| U+2000 | | En Quad |
| U+2001 | | Em Quad |
| U+2002 | | En Space |
| U+2003 | | Em Space |
| U+2004 | | Three-Per-Em Space |
| U+2005 | | Four-Per-Em Space |
| U+2006 | | Six-Per-Em Space |
| U+2007 | | Figure Space |
| U+2008 | | Punctuation Space |
| U+2009 | | Thin Space |
| U+200A | | Hair Space |
| U+2028 | | Line Separator |
| U+205F | MMSP | Medium Mathematical Space (MMSP) |
| U+3000 | | Ideographic Space |

The "new line" character belongs to the class `B`. I listed `S` and `WS` only for the purpose of completeness.

Now we can see clearly what `str.strip()` strips exactly.

References:

- [1] [Python3: str.strip()](https://docs.python.org/3/library/stdtypes.html#str.strip)
- [2] [Python3: str.isspace()](https://docs.python.org/3/library/stdtypes.html#str.isspace)
- [3] [compart: Unicode](https://www.compart.com/en/unicode)
- [4] ["5.7.1 General Category Values"](http://www.unicode.org/reports/tr44/#General_Category_Values)
- [5] [Unicode Database - Script](ftp://ftp.unicode.org/Public/UNIDATA/Scripts.txt)
- [6] ["5.7.2 Bidirectional Class Values"](http://www.unicode.org/reports/tr44/#Bidi_Class_Values)
- [7] [Unicode Bidirectional Algorithm](https://www.unicode.org/reports/tr9/)
- [8] [List of Unicode Characters of Bidirectional Class "Paragraph Separator"](https://www.compart.com/en/unicode/bidiclass/B)
- [9] [List of Unicode Characters of Bidirectional Class "Segment Separator"](https://www.compart.com/en/unicode/bidiclass/S)
- [10] [List of Unicode Characters of Bidirectional Class "White Space"](https://www.compart.com/en/unicode/bidiclass/WS)
