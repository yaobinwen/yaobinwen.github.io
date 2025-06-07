---
comments: true
date: 2025-06-07
layout: post
tags: [Tech, JavaScript]
title: Understanding JavaScript closures
---

A closure, as the [MDN document](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Closures) says:

> ... is the combination of **a function** bundled together (enclosed) with references to its **surrounding state (the lexical environment)**. In other words, a closure gives a function access to its outer scope. In JavaScript, closures are created **every time** a function is **created**, at function creation time.

We can infer the following points from the quoted paragraph above:

- A closure is a **run-time** entity.
- A closure is associated with a function. In other words, when we talk about a closure, we always have a particular function in mind and the closure is "the closure for this function under the spotlight."
- A closure includes two items: A function; the function's lexical environment.
- But the lexical environment may include other functions that the under-the-spotlight function can access.

What once confused me was the word "**created**". I once thought "created" means when the JavaScript interpreter parses the source code and allocates memory to store the function declarations. But the more I learn about closures, the more I realize it is actually about when the function is called at run-time.

When reasoning the behavior of a piece of code, it is crucial to have a clear mental model of which closure the current function is called.

Code 1: Constant.

```javascript
function main() {
  const num = 123;
  function displayNum() {
    console.log(num);
  }

  displayNum();
}

main();
```

Code 2: Lexical environment is not destroyed when there is a reference.

```javascript
function createDisplayNum() {
  const num = 123;
  function displayNum() {
    console.log(num);
  }

  return displayNum;
}

const dn = createDisplayNum();
dn();
```

Code 3: Inner function accesses the run-time value.

```javascript
function createDisplayNum(N) {
  function displayNum() {
    console.log(N);
  }

  return displayNum;
}

const dn1 = createDisplayNum(1);
dn1();

const dn10 = createDisplayNum(10);
dn10();
```

Code 4:

```javascript
let outerN = null;

function createDisplayNum(N) {
  outerN = N * 2;

  function displayNum() {
    console.log(`local N = ${N}; global N = ${outerN}`);
  }
  return displayNum;
}

const dn10 = createDisplayNum(10);
dn10();

const dn20 = createDisplayNum(20);
dn20();
// `dn20` affected `outerN` whose changes are visible to `dn10` because `dn10`
// refers to `outerN`.
dn10();
```

## Note 1: Functions

The section ["Defining functions"](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Functions#defining_functions) lists two ways of defining a function. The first way is "function declaration" which is the classical way of defining a function:

```javascript
function square(number) {
  return number * number;
}
```

Because the function declaration is not used in any kind of expressions, the JavaScript interpreter reads it, stores its definition in memory, and hoists it to the top of the current scope (in order to implement [function hoisting](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Functions#function_hoisting)).

The second way is "function expression":

```javascript
const square = function (number) {
  return number * number;
};
```

It looks quite similar to the declared version but a function expression is not hoisted. I don't know how the JavaScript interpreter works internally, but effectively it looks like the function is not created until this line of code is executed.
