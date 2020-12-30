---
comments: true
date: 2017-05-20
layout: post
tags: [Tech]
title: Python Process Exit Code
---

Recently in my project I need to use Python to spawn child processes from the main process and monitor the children's status. If a child doesn't exit normally, the main process will start it again. With the help of Python's multiprocessing module, the code looks like the following:

```python
#!/usr/bin/env python

import multiprocessing as mp
import random
import time

def _child():
    while True:
        time.sleep(1)
        random.seed(time.time())
        n = random.randint(1, 50)
        if n <= 10 :
            print "Child returns 0"
            return 0
        elif n <= 20:
            print "Child returns 1"
            return 1
        elif n <= 30:
            print "Child breaks while"
            break
        elif n <= 40:
            raise Exception("Terminated due to exception.")

def main():
    try:
        child = mp.Process(target=_child, name="Producer")
        child.start()
        while True:
            if not child.is_alive():
                print "child is not alive."
                print "exit code: %d" % child.exitcode
                break
            time.sleep(1)
    except KeyboardInterrupt:
        # Sleep so the child process can fully exit.
        time.sleep(1)
        print "child.exitcode = %s" % str(child.exitcode)


if __name__ == "__main__":
    main()
```

I summarized the results as the table below:

| Situation | Process.exitcode | Notes |
|:----------|:----------------:|:------|
| 'target' returns 0 | 0 ||
| 'target' returns non-zero | 0 | The return code of 'target' doesn't affect the process exit code. |
| 'target' returns nothing | 0 | Same as the above. |
| 'target' returns due to <br /> exception | 1 | |
| Child process is interrupted <br /> by Ctrl-C | 1 | Process.exitcode is not '-N'. |
| Child process is terminated <br /> by Linux 'kill' command | -N | 'N' is the signal number |
