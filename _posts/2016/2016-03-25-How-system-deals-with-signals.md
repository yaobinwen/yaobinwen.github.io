---
comments: true
date: 2016-03-25
layout: post
tags: [Tech]
title: How "os.system()" Deals with Signals
---

I encountered a problem the other day in the software platform that I am developing these days. The problem can be briefly described as three facts:

1. I am writing a Python script that will run infinitely, but is listening to the SIGINT to break the loop and terminate.
2. This Python script calls some underlying shell commands by using the ```os.system()``` in order to finish its tasks.
3. This Python script runs in the background so the user cannot terminate it by pressing the Ctrl + C. Instead, the user needs to use ```kill -2 <pid>``` to do so.

The problem was: Sometimes the ```os.system()``` calls a command that runs long time. During this time, executing ```kill -2 <pid>``` does not kill the target process successfully.

After searching on the Internet, I realized that this was caused by the fact that Python's ```os.system()```, which will further calls the C's ```system()``` function, ignores the SIGINT signal. In ```os.system()``` function, the command that is called is spawned as a new process, but this new process will listen and handle the signals. As a result, when the script is running in the foreground, pressing ```Ctrl + C``` will send a SIGINT to all the processes in the process group so they can be terminated as expected. However, ```kill``` sends the specified signal only to the specified process, not the entire group. Because the target process, in my case, is the one that calls the ```os.system()``` and it ignores the SIGINT, it cannot be terminated as expected.

Here are the notes that I made about this problem.

First, Python's ```os.system()``` calls C's ```system()``` function. This can be seen from the source code of ```os.system()```:

```c++
#ifdef HAVE_SYSTEM
PyDoc_STRVAR(posix_system__doc__,
"system(command) -> exit_status\n\n\
Execute the command (a string) in a subshell.");

static PyObject *
posix_system(PyObject *self, PyObject *args)
{
    char *command;
    long sts;
    if (!PyArg_ParseTuple(args, "s:system", &command))
        return NULL;
    Py_BEGIN_ALLOW_THREADS
    sts = system(command);
    Py_END_ALLOW_THREADS
    return PyInt_FromLong(sts);
}
#endif
```

([This question](http://stackoverflow.com/questions/14613223/python-os-library-source-code-location) shows where to find the source code.)

In glibc, C's ```system()``` function is an alias of ```do_system()``` function which is implemented with the calls to fork(), execl() and waitpid(), as shown in [its source code](http://code.metager.de/source/xref/gnu/glibc/sysdeps/posix/system.c).

The source code shows that the SIGINT and SIGQUIT are both ignored:

- ```Line 58```: A signal action ```sa``` is defined.
- ```Line 64```: ```sa```'s handler is assigned to [```SIG_IGN```](http://code.metager.de/source/xref/gnu/gcc/fixincludes/tests/base/sys/signal.h).
- ```Line 68 ~ 83```: Ignore the ```SIGINT``` and ```SIGQUIT```.

The lines in ```Line 115 ~ 119``` spawn a new child process. On the child side, the normal handling of ```SIGINT``` and ```SIGQUIT``` is restored, and then ```__execve()``` is called to run the specified program.

However, on the parent side, which is also the side which initiated the ```do_system()``` call, the handling of these two signals are not restored. Shortly, it calls the ```__waitpid()``` to wait for the completion of the just-spawned child process.

After the child process is completed, the normal signal handling is restored in the parent process, as shown in ```Line 157 ~ 171```.

## References

- [3.7.6 Signals](https://www.gnu.org/software/bash/manual/html_node/Signals.html)
- [Why is SIGINT not propagated to child process when sent to its parent process?](http://unix.stackexchange.com/questions/149741/why-is-sigint-not-propagated-to-child-process-when-sent-to-its-parent-process)
- [Proper handling of SIGINT/SIGQUIT](http://www.cons.org/cracauer/sigint.html)
- [Why Bash is like that: Signal propagation](http://www.vidarholen.net/contents/blog/?p=34)
- [Preventing propagation of SIGINT to Parent Process](http://unix.stackexchange.com/questions/80975/preventing-propagation-of-sigint-to-parent-process)
- [Behind the 'system(...)' Command](http://www.csc.villanova.edu/~mdamian/Past/csc2405sp13/notes/Exec.pdf)
