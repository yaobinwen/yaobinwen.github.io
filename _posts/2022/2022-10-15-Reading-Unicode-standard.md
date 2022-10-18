---
comments: true
date: 2022-10-15
layout: post
tags: [Tech,Unicode]
title: Reading of Unicode standard v15.0.0
---

(NOTE: This is still work in progress.)

## 0a. How to read the section indexes and reference markers

This document is divided into sections. The section index consists of two parts: Unicode standard section index and the section index in this document, in the form of `<S>-<s>`. For example, `7.1-2` refers to the second section in all the sections in this document that are related with the section 7.1 in the Unicode standard. The purpose is for extensibility: If later I want to insert a section, I only need to re-index a small number of sections in this document.

Regarding the reference markers:
- "[1]"refers to the referenced document [1]. Because the Unicode standard is a large piece of text, I only use it to when referring to the entire standard document.
- "[1] ch01" refers to the entire chapter 1 in [1]. For some short chapters (e.g., chapter 1), there is no need to specify a specific section or paragraph because it is very quick to skim the entire chapter.
- "[1] sec2.1" means the topic is discussed in section 2.1 in [1].
- "[1] fig2-1" refers to the Figure 2-1 in [1].
- "[1] tab2-4" refers to the Table 2-4 in [1].

## 0b. How this document is organized

The sections in this document generally follow the sequence of the chapters and sections in the Unicode standard, but not always. If I think a concept is more important to be introduced first, I may put this concept in an earlier section in this document even though it is discussed in a later section in the standard. I will try to use the reference markers to show the corresponding chapter/section in the standard.

## 2.1-1. Unicode architectural context: text processes

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

## 2.1-2. Text elements and characters

On the first thought, one may naturally think a character (such as the English letter "A") as the smallest unit for Unicode. It is true and false. It is true because [1] does define the encoding of "characters"; it is false because the "characters" that [1] discusses are not the "characters" that we perceive from our everyday experience.

The Unicode standard distinguishes "characters" and "text elements" because it thinks in the context of text processing, as said in [1] sec2.1:

> ... the division of text into text elements necessarily varies by language and text process.

I'll quote two examples here:

> In English, the letters "A" and "a" are usually distinct text elements for the process of rendering, but generally not distinct for the process of searching text. ... in the phrase "the quick brown fox," the sequence "fox" is a text element for the purpose of spell-checking.

Therefore, for [1], "characters" must be able to make up "text elements" efficiently and unambiguously for further text processing. As a matter of fact, in [1]:
- A character that Unicode standard encodes may or may not match to a character in a language(see [1] fig2-1 for example).
- The "characters" that the Unicode standard deal with are also called "**abstract characters**" ([1] 2.4).
- A text element is represented by a sequence of one or more characters.

## Codespace, code point, abstract characters, and encoded characters

The Unicode Standard specifies a **numeric value** (called **code point**) and a **name** for each of its **characters**.

The range of integers used to code the abstract characters is called the **codespace**. The Unicode standard codespace consists of the integers from `0` to `10FFFF`, comprising 1,114,112 code points available for assigning the repertoire of abstract characters.

When an abstract character is mapped or assigned to a particular code point in the codespace, it is then referred to as an **encoded character**. Note that:
- Some abstract characters may be associated with multiple, separately encoded characters (that is, be encoded "twice").
- An abstract character may be represented by a sequence of two (or more) other encoded characters (i.e., in the cases of dynamically composed sequences).
- See [1] fig2-8 for an example.

## Notational conventions

Use `U+<hexadecimal> <official name>` to describe a Unicode character. For example:
- `U+0061 latin small letter a`
- `U+201DF cjk unified ideograph-201df`

## 1-2. Basic Multilingual Plane (BMP)

The Unicode Standard contains **1,114,112** code points. The majority of the common characters used in the major languages of the world are encoded in the first **65,536** code points, also known as the **Basic Multilingual Plane (BMP)**.

## 2.1-3. Sorting and comparsion cannot rely on the code points

The subsection _Text Processes and Encoding_ in [1] sec2.1 says that the Unicode design aims to a wide variety of algorithm, but in particular:

> ... sorting and string comparison algorithms **cannot assume that the assignment of Unicode character code numbers provides an alphabetical ordering for lexicographic string comparison**. Culturally expected sorting orders require arbitrarily complex sorting algorithms. The expected sort sequence for the same characters differs across languages; thus, in general, **no single acceptable lexicographic ordering exists**.

## 2.2-1. Unicode design Principles

The Unicode design follows the 10 principles as follows. But as [1] sec2.2 says:

> Not all of these principles can be satisfied simultaneously. The design strikes a balance between maintaining consistency for the sake of simplicity and efficiency and maintaining compatibility for interchange with existing standards.

- 1). **Universality:** The Unicode Standard provides a single, universal repertoire.
- 2). **Efficiency:** Unicode text is simple to parse and process.
  - No escape characters or shift states.
- 3). **Characters, not glyphs:** The Unicode Standard encodes characters, not glyphs.
  - Glyphs are what a character looks like, i.e., "the shapes that characters can have when they are rendered or displayed."
  - "The Unicode Standard does not attempt to encode features such as language, font, size, positioning, glyphs, and so forth."
- 4). **Semantics:** Characters have well-defined semantics.
  - "These semantics are defined by explicitly assigned **character properties**, rather than implied through the character name or the position of a character in the code tables."
  - "The Unicode Standard identifies more than 100 different character properties, including numeric, casing, combination, and directionality properties."
- 5). **Plain text:** Unicode characters represent plain text.
  - Unicode deals with content (i.e., plain text), not style (i.e. rich text).
- 6). **Logical order:** The default for memory representation is logical order. See 2.2-2 for more details.
- 7). **Unification:** The Unicode Standard unifies duplicate characters within scripts across languages.
  - "Avoidance of duplicate encoding of characters is important to avoid visual ambiguity." This is important for security.
  - But there are also exceptions. For example, "there are three characters whose glyph is the same uppercase barred D shape, but they correspond to three distinct lowercase forms. Unifying these uppercase characters would have resulted in unnecessary complications for case mapping."
- 8). **Dynamic composition:** Accented forms can be dynamically composed.
  - Some text elements can be encoded either as static precomposed forms or by dynamic composition. Usually, the static precomposed forms are included for **compatibility** with existing standards, but the Unicode standard provides an equivalent dynamically composed sequence.
- 9). **Stability:** Characters, once assigned, cannot be reassigned and key properties are immutable.
- 10). **Convertibility:** Accurate convertibility is guaranteed between the Unicode Standard and other widely accepted standards.

## 2.2-2. Logical order (i.e., memory representation order)

[1] 2.2 defines **logical order** as follows:

> The order in which Unicode text is stored in the **memory representation** is called _logical order_. This order **roughly** corresponds to the order in which text is typed in via the keyboard; it also **roughly** corresponds to phonetic order.

[1] fig2-4 is an example to show the difference between _logical order_ and _display order_. The example is a mix of English and Arabic:
- All the English and Arabic characters are stored from left to right in the computer memory.
- When displayed, the English words are displayed left-to-right, while the Arabic part is displayed right-to-left.

> The Unicode Standard precisely defines the conversion of Unicode text **from logical order to the order of readable (displayed) text** so as to ensure consistent legibility. ... therefore **includes characters to explicitly specify changes in direction when necessary**.

## 2.5-1. Encoding forms

Unicode characters are represented in one of three encoding forms:
- a 32-bit form (UTF-32):
  - Width: always 32 bits.
  - **Fixed width**, so it has a one-to-one relationship between encoded character and code unit and is easy to access.
  - **Need to consider endianness.**
  - **Preferred usage**:
    - memory or disk storage space is not a concern.
    - fixed-width, single code unit access to characters is desired (such as Python 3 strings)
- a 16-bit form (UTF-16):
  - Width: always 16 bits for BMP characters; 32 bits for others.
  - **Optimized for BMP:** Characters in BMP are encoded into single 16-bit code units, so UTF-16 can be treated as a fixed-width encoding form (only) for BMP.
  - **Need to consider endianness.**
  - **Preferred usage:** Maintain a balance between storage space and efficient access.
- an 8-bit form (UTF-8)
  - Width: can be 8 bits, 16 bits, 24 bits, or 32 bits.
  - **Variable width**
  - **ASCII transparent**
  - Data size: Compared with UTF-16:
    - **Much smaller** for ASCII syntax and Western languages.
    - **Much larger** for Asian languages such as Hindi, Thai, Chinese, Japanese, and Korean.
  - **No need to consider endianness**
  - **Preferred usage:** where UTF-16 and UTF-32 are not the good fits.

The Unicode Standard is code-for-code identical with International Standard **ISO/IEC 10646:2020**, Information Technology—Universal Coded Character Set (UCS), known as the **Universal Character Set (UCS)**.

("UTF" is a carryover from earlier terminology meaning _Unicode (or UCS) Transformation Format_.)

## 2.6-1. Encoding schemes

When exchanging textual data from one machine to another, the code units must be **serialized** to a sequence of bytes. The serialization must consider the order of bits due to the existence of big-endianness and little-endianness.

> In the Unicode Standard, the specifications of the distinct types of byte serializations to be used with Unicode data are known as Unicode **encoding schemes**.
>
> A **character encoding scheme** consists of a specified character encoding form plus a specification of how the code units are serialized into bytes. The Unicode Standard also specifies the use of an initial **byte order mark (BOM)** to explicitly differentiate big-endian or little-endian data in some of the Unicode encoding schemes.

[1] tab2-4: The seven Unicode encoding schemes:

| Encoding Scheme | Endian Order | BOM Allowed? |
|:---------------:|:------------:|:------------:|
| UTF-8 | N/A | Yes |
| UTF-16 | Either | Yes |
| UTF-16BE | Big-endian | No |
| UTF-16LE | Little-endian | No |
| UTF-32 | Either | Yes |
| UTF-32BE | Big-endian | No |
| UTF-32LE | Little-endian | No |

## 2.6-2. Encoding forms vs encoding schemes

[1] tab2-4 shows that "some of the Unicode encoding schemes have the same labels as the three Unicode encoding forms" (i.e., "UTF-8", "UTF-16", and "UTF-32" can refer to either an encoding form or an encoding scheme). Therefore, it is important to know in what context these terms are used:
- Encoding forms refer to "integral data units in memory or in APIs, and **byte order is irrelevant**."
- Encoding schemes refer to "byte-serialized data, as for streaming I/O or in
file storage, and **byte order must be specified or determinable**."

## 2.6-3. Charsets

> The Internet Assigned Numbers Authority (IANA) maintains a registry of **charset names** used on the Internet. Those charset names are very close in meaning to the Unicode character encoding model's concept of character encoding schemes, and all of the Unicode character encoding schemes are, in fact, registered as **charsets**.

## 2.10-1. Writing directions

**Directionality** is about the convention for arranging characters into lines on a page or screen.

[1] fig2-16 lists a few interesting writing directions:

| Chars | Lines | Examples |
|:-----:|:-----:|:--------:|
| Left -> Right | Top -> Bottom | Latin scripts |
| Both | Top -> Bottom | Hebrew; Arabic |
| Top -> Bottom | Right -> Left | Many East Asian scripts |
| Top -> Bottom | Left -> Right | Mongolian |
| Boustrophedon ("ox-turning") | Top -> Bottom | Early Greek |

## References

- [1] [Unicode® 15.0.0](https://www.unicode.org/versions/Unicode15.0.0/)

(To be continued)
