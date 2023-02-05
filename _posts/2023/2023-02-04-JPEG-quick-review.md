---
comments: true
date: 2023-02-04
layout: post
tags: [Tech]
title: A quick review of JPEG format
---

This article is a quick review of the JPEG format to help me refresh my memory after not using it for a long time. I learned it because I wanted to parse the binary content to retrieve the height and width of a JPEG image, so I have only learned as much as needed to accomplish the task.

## Documentation

I've only used [1] [DIGITAL COMPRESSION AND CODING OF CONTINUOUS-TONE STILL IMAGES - REQUIREMENTS AND GUIDELINES](https://www.w3.org/Graphics/JPEG/itu-t81.pdf) as the reference. This article is a guide of how to read [1].

## How to Read [1]

Clause 3 _Definitions, abbreviations and symbols_ is an exhausting list of the terms and symbols that are used. It's a good reference to quickly find related concepts and refresh the memory but I feel it's not good enough for learning if you study the document the first time.

Clause 4 is a good overview of the JPEG format and should be used as the main reference.

Annex B _Compressed data formats_ is a comprehensive description of the binary data format and should be used to understand the binary format. Figure B.16 _Flow of compressed data syntax_ and Figure B.17 _Flow of marker segment_ provide a very good summary of the binary format.

I haven't read the other parts of [1] very much.

## JPEG and JFIF

"JPEG" is actually the name of the working group ("Joint Photographic Experts Group").

The so-called "JPEG" format is officially called "JFIF"("JPEG File Interchange Format").

## Important Concepts

When you read [1], you will frequently encounter the following terms. I'll list them here for a quick refresh of memory.

### Component

See [1] 4.1.

> A colour image consists of multiple _components_; a grayscale image consists only of a single _component_.

### lossy vs lossless

See [1] 4.2.

["Lossless compression"](https://en.wikipedia.org/wiki/Lossless_compression) "allows the original data to be perfectly reconstructed from the compressed data with no loss of information."

"Lossy" is surely "not lossless".

[1] specifies encoding and decoding processes that support both types of compression.

### DCT-based and non-DCT-based

See [1] 4.2.

"DCT" is _discrete cosine transform_.

The DCT-based encoding and decoding processes are lossy. The others (not based on DCT) are lossless.

The simplest DCT-based coding process is called _baseline sequential_ process which is sufficient for most of the applications. There are other extended DCT-based processes but baseline sequential process is always needed to provide a default capability.

### Tables

See [1] 4.3 and 4.4.

The encoding process needs two kinds of tables to work: _quantization table_ and tables for the entropy encoding process. These two kinds of tables are needed when decoing the image. This is why there are segments for tables.

### Modes of operation

See [1] 4.5. Figure 9 and Figure 10 are helpful to understand the topic.

There are four distinct modes of operation under which the various coding processes are defined:
- sequential DCT-based:
  - Like "processing the image line by line".
  - One _frame_ with one _scan_.
- progressive DCT-based
  - Like "processing the image layer by layer".
  - One _frame_ with multiple _scans_.
- lossless
- hierarchical:
  - Coded in a sequence of _frames_.

### Structure of compressed data

See [1] 4.10.

- Interchange format: The full format
- Abbreviated format for compressed image data: This is interchange format without table specifications.
- Abbreviated format for table-specification data: This is interchange format with only table specifications.

### Image, frame, and scan

See [1] 4.11.

> Compressed image data consists of **only one image**. An image contains only **one frame** in the cases of sequential and progressive coding processes; an image contains **multiple frames** for the hierarchical mode.
>
> A frame contains **one or more scans**. For sequential processes, a scan contains a complete encoding of **one or more image components**. ... For progressive processes, a scan contains a partial encoding of all data units from **one or more image components**. Components shall not be interleaved in progressive mode, except for the DC coefficients in the first scan for each component of a progressive frame.

## Sample Code

I wrote [a piece of JavaScript code](https://github.com/yaobinwen/react-box/blob/master/code/src/modules/ImageFormatJPEG.js) that reads the binary content of an JPEG image and returns its height and width. But it doesn't handle JPEG images in hierarchical mode.
