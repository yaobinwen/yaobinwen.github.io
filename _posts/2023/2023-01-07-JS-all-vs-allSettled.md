---
comments: true
date: 2023-01-07
layout: post
tags: [Tech;Frontend;JavaScript;Async;Promise]
title: "JavaScript: `Promise.all()` vs `Promise.allSettled()`"
---

`Promise.all()` [1] and `Promise.allSettled()` [2] are similar because they both deal with a group of promises. But they behave differently when some of the promises get rejected.

[1] and [2] mention `all()` and `allSettled()` are fulfilled when the input promise list is empty. But I'll assume the input promise list is not empty in this article.

The similarities and differences can be summarized as follows:
- `all()` is fulfilled when the input promises are **all fulfill**; `allSettled()` is fulfilled when all the input promises are **all settled** (either fulfilled or rejected).
- When `all()` is fulfilled, the fulfillment result is an array of the **fulfilled values without promise states** (because `all()` is only fulfilled when all the promises are fulfilled so the promise states must be `fulfilled`). When `allSettled()` is fulfilled, the fulfillment result is an array of the **promise states** plus the fulfilled values or rejected reasons.
- `all()` is rejected when one of the input promises is rejected; `allSettled()` is never rejected (according to [2], [3], and also my test).
- If one of the input promises is not resolved (fulfilled or rejected), `all()` or `allSettled()` is not resolved.

The following code can demonstrate how they work. I've put comments to explain the code. One can save the code into a file like `all_vs_allSettled.js` and run `nodejs all_vs_allSettled.js` to get the results. The code is also available [here](https://github.com/yaobinwen/robin_on_rails/blob/master/JavaScript/Promise/all_vs_allSettled.js):

```javascript
function promise(delay_ms, resolution, res_value) {
  let p = new Promise((resolve, reject) => {
    setTimeout(() => {
      if (resolution === "fulfill") {
        resolve(res_value)
      } else if (resolution === "reject") {
        reject(res_value)
      } else if (resolution === "never_resolve") {
        // The promise will never resolve.
      } else {
        throw new Error(`unkown resolution "${resolution}"`)
      }
    }, delay_ms)
  })
  .then(value => {
    console.log(`fulfilled value: ${value}`)
    return value
  })
  .catch(reason => {
    console.error(`rejected reason: ${reason}`)
    throw new Error(reason)
  })

  return p
}

function run_all(promises) {
  return Promise.all(promises)
    .then(result => {
      console.info(`Promise.all: fulfilled result: ${result}`)
    })
    .catch(reason => {
      console.error(`Promise.all: rejected reason: ${reason}`)
    })
}

// Output:
//
// fulfilled value: 1
// fulfilled value: 2
// Promise.all: fulfilled result: 1,2
//
// Notes: `all()` is not fulfilled until all the input promises fulfill.
run_all([
  promise(100, "fulfill", 1),
  promise(110, "fulfill", 2),
])

// Output:
//
// fulfilled value: 3
// rejected reason: 4
// Promise.all: rejected reason: Error: 4
//
// Notes: `all()` is rejected if one of the input promises gets rejected.
run_all([
  promise(120, "fulfill", 3),
  promise(130, "reject", 4),
])

// Output:
//
// rejected reason: 5
// Promise.all: rejected reason: Error: 5
// rejected reason: 6
//
// Notes: `all()` is rejected (i.e. resolved) once one of the input promises is
// rejected, regardless if other promises are resolved or not.
run_all([
  promise(150, "reject", 5),
  promise(160, "reject", 6),
])

// Output:
//
// fulfilled value: 7
//
// Notes: `all()` is not fulfilled until all the input promises fulfill. If
// one promise never fulfill, `all()` will never fulfill either.
run_all([
  promise(170, "fulfill", 7),
  promise(180, "never_resolve", 8),
])

// Output:
//
// rejected reason: 10
// Promise.all: rejected reason: Error: 10
//
// Notes: Again, `all()` is rejected once one of the input promiese is
// rejected. The other promises may take much longer to fulfill or never
// resolve, but that doesn't matter.
run_all([
  promise(190, "never_resolve", 9),
  promise(200, "reject", 10),
])

function run_allSettled(promises) {
  return Promise.allSettled(promises)
    .then(result => {
      console.info("Promise.allSettled: fulfilled result: ", result)
    })
    .catch(() => {
      throw new Error("Promise.allSettled catch block should not be called")
    })
}

// Output:
//
// fulfilled value: A
// fulfilled value: B
// Promise.allSettled: fulfilled result:  [
//   { status: 'fulfilled', value: 'A' },
//   { status: 'fulfilled', value: 'B' }
// ]
//
// Notes: `allSettled()` is fulfilled when all the input promises are settled.
run_allSettled([
  promise(500, "fulfill", "A"),
  promise(510, "fulfill", "B"),
])

// Output:
//
// rejected reason: C
// fulfilled value: D
// Promise.allSettled: fulfilled result:  [
//   {
//     status: 'rejected',
//     reason: Error: C
//         at /home/ywen/yaobin/github/robin_on_rails/JavaScript/Promise/API/all_allSettled/all.js:21:11
//   },
//   { status: 'fulfilled', value: 'D' }
// ]
//
// Notes: `allSettled()` is fulfilled when all the input promises are settled.
run_allSettled([
  promise(520, "reject", "C"),
  promise(530, "fulfill", "D"),
])

// Output:
//
// rejected reason: E
// rejected reason: F
// Promise.allSettled: fulfilled result:  [
//   {
//     status: 'rejected',
//     reason: Error: E
//         at /home/ywen/yaobin/github/robin_on_rails/JavaScript/Promise/API/all_allSettled/all.js:21:11
//   },
//   {
//     status: 'rejected',
//     reason: Error: F
//         at /home/ywen/yaobin/github/robin_on_rails/JavaScript/Promise/API/all_allSettled/all.js:21:11
//   }
// ]
//
// Notes: `allSettled()` is fulfilled when all the input promises are settled.
run_allSettled([
  promise(540, "reject", "E"),
  promise(550, "reject", "F"),
])

// Output:
//
// fulfilled value: G
//
// Notes: `allSettled()` is not fulfilled until all the input promises are
// settled.
run_allSettled([
  promise(560, "fulfill", "G"),
  promise(570, "never_resolve", "H"),
])

// Output:
//
// rejected reason: J
//
// Notes: `allSettled()` is not fulfilled until all the input promises are
// settled.
run_allSettled([
  promise(580, "never_resolve", "I"),
  promise(590, "reject", "J"),
])

```

# References

- [1] [MDN Web Docs: Promise.all()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all)
- [2] [MDN Web Docs: Promise.allSettled()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/allSettled)
- [3] [Corey Cleary: Better handling of rejections using Promise.allSettled()](https://www.coreycleary.me/better-handling-of-rejections-using-promise-allsettled): "`Promise.allSettled()` will never reject - instead it will wait for all functions passed in the array to either resolve or reject."
