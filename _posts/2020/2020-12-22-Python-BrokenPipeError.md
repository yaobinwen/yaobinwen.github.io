---
comments: true
date: 2020-12-22
layout: post
tags: [Tech]
title: The "BrokenPipeError" in Python
---

Today I encountered the `BrokenPipeError` when working on a personal project. This error can be reproduced using two simple scripts (`upstream.py` and `downstream.sh`):

```python
#!/usr/bin python3
# -*- coding: utf-8 -*-

print("Hello, world!")
```

```shell
#!/bin/sh

exit 0
```

Yes, the Shell script does nothing but exits instantly.

When piping them together `./upstream.py | ./downstream.sh`, I got the following error:

```
Exception ignored in: <_io.TextIOWrapper name='<stdout>' mode='w' encoding='UTF-8'>
BrokenPipeError: [Errno 32] Broken pipe
```

The [`BrokenPipeError` documentation](https://docs.python.org/3.6/library/exceptions.html#BrokenPipeError) explains this exception:

> A subclass of `ConnectionError`, raised when trying to write on a pipe while the other end has been closed, or trying to write on a socket which has been shutdown for writing. Corresponds to errno `EPIPE` and `ESHUTDOWN`.

Sockets are not involved in our case. So the `BrokenPipeError` must be raised because the read end of the pipe (`downstream.sh`) was closed when the write end (`upstream.py`) was still trying to write to the pipe.

This can be confirmed by the book [APUE (3e)](http://www.apuebook.com/apue3e.html) which describes the rules in Section 15.2:

> When one end of a pipe is closed, two rules apply.
>
> 1. If we read from a pipe whose write end has been closed, read returns 0 to indicate an end of file after all the data has been read. (Technically, we should say that this end of file is not generated until there are no more writers for the pipe. It's possible to duplicate a pipe descriptor so that multiple processes have the pipe open for writing. Normally, however, there is a single reader and a single writer for a pipe. When we get to FIFOs in the next section, we'll see that often there are multiple writers for a single FIFO.)
>
> 2. If we write to a pipe whose read end has been closed, the signal SIGPIPE is generated. If we either ignore the signal or catch it and return from the signal handler, write returns -1 with errno set to EPIPE.

I cited both paragraphs for completeness but only the second paragraph matters for our current topic.

Therefore, to fix this problem, we just need to make sure that `downstream.sh` is always available before `upstream.py` finishes writing. We can change `downstream.sh` to the following:

```shell
#!/bin/sh

C=$(cat < /dev/stdin)
echo $C

exit 0
```

Now we keep waiting for `stdin` until the end of it, so `downstream.sh` only exits when `upstream.py` finishes writing to `stdin`.

[This Stack Overflow answer](https://stackoverflow.com/a/26738736/630364) mentions the bug ["Improve reporting of broken stdout pipe during interpreter shutdown"](https://bugs.python.org/issue11380). [One of its comment](https://bugs.python.org/issue11380,#msg198316) says:

> This is reasonable, since a broken pipeline *is* an error that the user may need to do something about (e.g. as with echo, they next pipeline stage may not being invoked correctly, thus breaking the pipe).

In other words, the developers think it important to warn the user of the abnormal condition.

By the way, the comment also mentions an even simpler way to reproduce the error [1]:

```shell
python3 -c 'print("Hello, world!")' | echo
```

If we can't fix the downstream program of the pipe, we can try to do something to the upstream program to get rid of the message:

```python
#!/usr/bin/python3
# -*- coding: utf-8 -*-

import sys

try:
  print("Hello, world!")
except BrokenPipeError:
  # Silence the error.
  pass

# Close stderr before exiting to get rid of the message.
sys.stderr.close()
```

However, I don't think this is a "fix" because the downstream program still exits before the upstream program finishes writing. What is done here merely "hides" the information that shows the error, which may look cleaner but is inappropriate: the user would lose a chance to fix the real issue.

Note [1]: If you run the following (Ubuntu 18.04, `bash`):

```shell
python3 -c "print('Hello, world!')"
```

You will get the error:

```
bash: !': event not found
```

This is caused by the [Bash Pitfalls #23: echo "Hello World!"](https://mywiki.wooledge.org/BashPitfalls#echo_.22Hello_World.21.22).
