---
comments: true
date: 2022-10-15
layout: post
tags: [Tech,Unicode]
title: Reading of Unicode standard v15.0.0
---

(NOTE: This is still work in progress.)

## 1. How to read the reference markers

- "[1]"refers to the referenced document [1]. Because the Unicode standard is a large piece of text, I only use it to when referring to the entire standard document.
- "[1] ch01" refers to the entire chapter 1 in [1]. For some short chapters (e.g., chapter 1), there is no need to specify a specific section or paragraph because it is very quick to skim the entire chapter.
- "[1] sec2.1" means the topic is discussed in section 2.1 in [1].
- "[1] fig2-1" refers to the Figure 2-1 in [1].

## 2. A really quick overview ([1] )

The Unicode Standard specifies a **numeric value** (code point) and a **name** for each of its **characters**.

Unicode characters are represented in one of three encoding forms:
- a 32-bit form (UTF-32)
- a 16-bit form (UTF-16)
- an 8-bit form (UTF-8)

The Unicode Standard is code-for-code identical with International Standard **ISO/IEC 10646:2020**, Information Technology—Universal Coded Character Set (UCS), known as the **Universal Character Set (UCS)**.

The Unicode Standard contains **1,114,112** code points. The majority of the common characters used in the major languages of the world are encoded in the first **65,536** code points, also known as the **Basic Multilingual Plane (BMP)**.

## 3. Unicode architectural context: text processes

What is the purpose of defining Unicode? It is **not** to simply organize all the worldwide characters into a space and assign numbers to them. Instead, **the purpose is to make text processing easier to implement** ([1] sec2.1):

> The interesting end products are **not** the character codes **but rather the text processes**, because these directly serve the needs of a system's users.

It then lists the common basic text processings:

- Rendering characters visible (including ligatures, contextual forms, and so on).
- Breaking lines while rendering (including hyphenation).
- Modifying appearance, such as point size, kerning, underlining, slant, and weight (light, demi, bold, and so on).
- Determining units such as "word" and "sentence".
- Interacting with users in processes such as selecting and highlighting text
- Accepting keyboard input and editing stored text through insertion and deletion
- Comparing text in operations such as in searching or determining the sort order of two strings
- Analyzing text content in operations such as spell-checking, hyphenation, and parsing morphology (that is, determining word roots, stems, and affixes)
- Treating text as bulk data for operations such as compressing and decompressing, truncating, transmitting, and receiving

Thinking about Unicode in this context can make it easier for us to understand why Unicode picks one particular design over another.

## 4. Text elements and characters

On the first thought, one may naturally think a character (such as the English letter "A") as the smallest unit for Unicode. It is true and false. It is true because [1] does define the encoding of "characters"; it is false because the "characters" that [1] discusses are not the "characters" that we perceive from our everyday experience.

The Unicode standard distinguishes "characters" and "text elements" because it thinks in the context of text processing, as said in [1] sec2.1:

> ... the division of text into text elements necessarily varies by language and text process.

I'll quote two examples here:

> In English, the letters "A" and "a" are usually distinct text elements for the process of rendering, but generally not distinct for the process of searching text. ... in the phrase "the quick brown fox," the sequence "fox" is a text element for the purpose of spell-checking.

Therefore, for [1], "characters" must be able to make up "text elements" efficiently and unambiguously for further text processing. As a result:
- A character that Unicode standard encodes may or may not match to a character in a language(see [1] fig2-1 for example).
- A text element is represented by a sequence of one or more characters.

## References

- [1] [Unicode® 15.0.0](https://www.unicode.org/versions/Unicode15.0.0/)

(To be continued)
