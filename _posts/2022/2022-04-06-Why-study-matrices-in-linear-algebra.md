---
comments: true
date: 2022-04-06
layout: post
tags: [Math]
title: "Why do we study matrices in linear algebra?"
---

I learned linear algebra in college. I also noticed that most of the textbooks of linear algebra start with the definition of _matrix_ and how calculations (e.g., addition, multiplication) work on matrices. However, the textbooks rarely explain two questions:

- 1). Why were matrices developed in the first place?
- 2). Why is a matrix defined in the shape of a rectangle? Why not a triangle or a circle?

I agree that these questions are not at all important to learning linear algebra, but I also find it frustrating not to be able to find a good answer easily. So I decided to do some homework by myself. This article is the notes after I skimmed the following articles:

- [ON THE HISTORY OF SOME LINEAR ALGEBRA CONCEPTS: FROM BABYLON TO PRE-TECHNOLOGY](https://www.tojsat.net/journals/tojsat/articles/v07i01/v07i01-12.pdf) by Sinan AYDIN.
- [A Brief History of Linear Algebra](http://www.math.utah.edu/~gustafso/s2012/2270/web-projects/christensen-HistoryLinearAlgebra.pdf) by Jeff Christensen
- [A Brief History of Linear Algebra and Matrix Theory](https://convexoptimization.com/TOOLS/Vitulli.pdf)
- [Hermann Grassmann and the Creation of Linear Algebra](https://www.maa.org/programs/faculty-and-departments/course-communities/hermann-grassmann-and-the-creation-of-linear-algebra)
- [Early History of Linear Algebra](http://rhart.org/algebra/) by [Roger Hart](http://www.rhart.org/)
- [Matrices and determinants](https://mathshistory.st-andrews.ac.uk/HistTopics/Matrices_and_determinants/)

In general, it is known that people, e.g., in Babylon and ancient China, have been studying and solving problems of linear systems for centuries. Being a Chinese myself, I remember I learned about the problem of "hens and rabbits in the same cage" ([鸡兔同笼](https://zh.wikipedia.org/wiki/%E9%B8%A1%E5%85%94%E5%90%8C%E7%AC%BC)) which was probably published between 420AD and 589AD (i.e., during the [Northern and Southern dynasties](https://en.wikipedia.org/wiki/Northern_and_Southern_dynasties)) and  which I can translate as follows:

> There are hens and rabbits in the same cage with totally 35 heads and 94 feet. How many hens and rabbits are there?

Mathematicians therefore have been studying how to solve the system of linear equations. Along the way, they gradually discovered the important relationship between the coefficients of the unknown variables and the solutions. One commonly mentioned piece of work is the [Cramer's rule](https://en.wikipedia.org/wiki/Cramer%27s_rule) which describes how to calculate the solution using the [determinant](https://en.wikipedia.org/wiki/Determinant) of the coefficients. However, Cramer's rule was published in 1750, years before matrix was officially introduced.

Gauss developed [Gaussian elimination](https://en.wikipedia.org/wiki/Gaussian_elimination) which is an algorithm that "consists of a sequence of operations performed on the corresponding matrix of coefficients." But this work was also done before matrices were invented.

As mathematicians realized the importance of the study of the coefficients of the unknown variables, the need of a proper notation of "the arrays of coefficients" and definition of the calculations on them arose. In 1850, the term "matrix" was officially introduced by the English mathematician [James Sylvester](https://en.wikipedia.org/wiki/James_Joseph_Sylvester) who also developed the early matrix theory with [Arthur Cayley](https://en.wikipedia.org/wiki/Arthur_Cayley).

Therefore, it is now easier to answer the two questions at the beginning:

- 1). Matrices were developed because mathematicians needed a tool to work on the coefficients of the unknown variables in a system of linear equations.
- 2). Because the coefficients of the unknown variables in a system of linear equations naturally form the shape of a rectangle, the matrices are thus naturally defined in the same shape.

Similar to other mathematical tools, although matrices were initially invented to handle the coefficients, their use of today have spread to other aspects. For example, we can use a matrix to represent an image in the computer, with each number in the matrix corresponding to a pixel on the image. The question [_What is the usefulness of matrices?_](https://math.stackexchange.com/questions/160328/what-is-the-usefulness-of-matrices) also mentions the uses of matrices.
