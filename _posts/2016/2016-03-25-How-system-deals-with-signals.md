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

In glibc, C's ```system()``` function is an alias of ```do_system()``` function which is implemented with the calls to fork(), execl() and waitpid(), as shown in [its source code](https://github.com/lattera/glibc/blob/master/sysdeps/posix/system.c) as follows:

```c
/* Execute LINE as a shell command, returning its status.  */
static int
do_system (const char *line)
{
  int status, save;
  pid_t pid;
  struct sigaction sa;
#ifndef _LIBC_REENTRANT
  struct sigaction intr, quit;
#endif
  sigset_t omask;

  sa.sa_handler = SIG_IGN;
  sa.sa_flags = 0;
  __sigemptyset (&sa.sa_mask);

  DO_LOCK ();
  if (ADD_REF () == 0)
    {
      if (__sigaction (SIGINT, &sa, &intr) < 0)
	{
	  (void) SUB_REF ();
	  goto out;
	}
      if (__sigaction (SIGQUIT, &sa, &quit) < 0)
	{
	  save = errno;
	  (void) SUB_REF ();
	  goto out_restore_sigint;
	}
    }
  DO_UNLOCK ();

  /* We reuse the bitmap in the 'sa' structure.  */
  __sigaddset (&sa.sa_mask, SIGCHLD);
  save = errno;
  if (__sigprocmask (SIG_BLOCK, &sa.sa_mask, &omask) < 0)
    {
#ifndef _LIBC
      if (errno == ENOSYS)
	__set_errno (save);
      else
#endif
	{
	  DO_LOCK ();
	  if (SUB_REF () == 0)
	    {
	      save = errno;
	      (void) __sigaction (SIGQUIT, &quit, (struct sigaction *) NULL);
	    out_restore_sigint:
	      (void) __sigaction (SIGINT, &intr, (struct sigaction *) NULL);
	      __set_errno (save);
	    }
	out:
	  DO_UNLOCK ();
	  return -1;
	}
    }

#ifdef CLEANUP_HANDLER
  CLEANUP_HANDLER;
#endif

#ifdef FORK
  pid = FORK ();
#else
  pid = __fork ();
#endif
  if (pid == (pid_t) 0)
    {
      /* Child side.  */
      const char *new_argv[4];
      new_argv[0] = SHELL_NAME;
      new_argv[1] = "-c";
      new_argv[2] = line;
      new_argv[3] = NULL;

      /* Restore the signals.  */
      (void) __sigaction (SIGINT, &intr, (struct sigaction *) NULL);
      (void) __sigaction (SIGQUIT, &quit, (struct sigaction *) NULL);
      (void) __sigprocmask (SIG_SETMASK, &omask, (sigset_t *) NULL);
      INIT_LOCK ();

      /* Exec the shell.  */
      (void) __execve (SHELL_PATH, (char *const *) new_argv, __environ);
      _exit (127);
    }
  else if (pid < (pid_t) 0)
    /* The fork failed.  */
    status = -1;
  else
    /* Parent side.  */
    {
      /* Note the system() is a cancellation point.  But since we call
	 waitpid() which itself is a cancellation point we do not
	 have to do anything here.  */
      if (TEMP_FAILURE_RETRY (__waitpid (pid, &status, 0)) != pid)
	status = -1;
    }

#ifdef CLEANUP_HANDLER
  CLEANUP_RESET;
#endif

  save = errno;
  DO_LOCK ();
  if ((SUB_REF () == 0
       && (__sigaction (SIGINT, &intr, (struct sigaction *) NULL)
	   | __sigaction (SIGQUIT, &quit, (struct sigaction *) NULL)) != 0)
      || __sigprocmask (SIG_SETMASK, &omask, (sigset_t *) NULL) != 0)
    {
#ifndef _LIBC
      /* glibc cannot be used on systems without waitpid.  */
      if (errno == ENOSYS)
	__set_errno (save);
      else
#endif
	status = -1;
    }
  DO_UNLOCK ();

  return status;
}
```

The source code shows that the SIGINT and SIGQUIT are both ignored:

- The line `struct sigaction sa;` defines a signal action.
- The line `sa.sa_handler = SIG_IGN;` assigns the special value `SIG_IGN` to the handler of this signal action. According to [POSIX](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/signal.h.html), `SIG_IGN` means "Request that signal be ignored." Therefore, the signal that's handled by this handler is effectively ignored.
- The lines `__sigaction (SIGINT, &sa, &intr)` and `__sigaction (SIGQUIT, &sa, &quit)` mean that we want to handle the signals `SIGINT` and `SIGQUIT` using the handler `sa`. Because `sa` is defined to ignore the signal, these lines effectively ignore the signals `SIGINT` and `SIGQUIT`.

The following lines spawns a new child process.

```c
#ifdef FORK
  pid = FORK ();
#else
  pid = __fork ();
#endif
```

On the child side as shown in the code below, the normal handling of `SIGINT` and `SIGQUIT` is restored, and then `__execve` is called to run the specified program. If the program is run successfully, the line `_exit (127)` should never be reached. Therefore, if anything goes wrong with running the specified program, `_exit (127)` is run to tell the caller that the specified program fails to be launched.

```c
  if (pid == (pid_t) 0)
    {
      /* Child side.  */
      const char *new_argv[4];
      new_argv[0] = SHELL_NAME;
      new_argv[1] = "-c";
      new_argv[2] = line;
      new_argv[3] = NULL;

      /* Restore the signals.  */
      (void) __sigaction (SIGINT, &intr, (struct sigaction *) NULL);
      (void) __sigaction (SIGQUIT, &quit, (struct sigaction *) NULL);
      (void) __sigprocmask (SIG_SETMASK, &omask, (sigset_t *) NULL);
      INIT_LOCK ();

      /* Exec the shell.  */
      (void) __execve (SHELL_PATH, (char *const *) new_argv, __environ);
      _exit (127);
    }
    /* ... */
```

However, on the parent side in the code below, which is also the side which initiated the ```do_system()``` call, the handling of these two signals are not restored. Shortly, it calls the `__waitpid()` to wait for the completion of the just-spawned child process.

```c
  else
    /* Parent side.  */
    {
      /* Note the system() is a cancellation point.  But since we call
	 waitpid() which itself is a cancellation point we do not
	 have to do anything here.  */
      if (TEMP_FAILURE_RETRY (__waitpid (pid, &status, 0)) != pid)
	status = -1;
    }
```

After the child process is completed, the normal signal handling is restored in the parent process, as shown in the following code:

```c
  DO_LOCK ();
  if ((SUB_REF () == 0
       && (__sigaction (SIGINT, &intr, (struct sigaction *) NULL)
	   | __sigaction (SIGQUIT, &quit, (struct sigaction *) NULL)) != 0)
      || __sigprocmask (SIG_SETMASK, &omask, (sigset_t *) NULL) != 0)
    {
#ifndef _LIBC
      /* glibc cannot be used on systems without waitpid.  */
      if (errno == ENOSYS)
	__set_errno (save);
      else
#endif
	status = -1;
    }
  DO_UNLOCK ();
```

## References

- [3.7.6 Signals](https://www.gnu.org/software/bash/manual/html_node/Signals.html)
- [Why is SIGINT not propagated to child process when sent to its parent process?](http://unix.stackexchange.com/questions/149741/why-is-sigint-not-propagated-to-child-process-when-sent-to-its-parent-process)
- [Proper handling of SIGINT/SIGQUIT](http://www.cons.org/cracauer/sigint.html)
- [Why Bash is like that: Signal propagation](http://www.vidarholen.net/contents/blog/?p=34)
- [Preventing propagation of SIGINT to Parent Process](http://unix.stackexchange.com/questions/80975/preventing-propagation-of-sigint-to-parent-process)
- [Behind the 'system(...)' Command](http://www.csc.villanova.edu/~mdamian/Past/csc2405sp13/notes/Exec.pdf)
