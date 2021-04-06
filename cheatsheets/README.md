# Cheat Sheet

## FAL (Frequently Accessed Links)

[Linux: Filesystem Hierarchy Standard](https://refspecs.linuxfoundation.org/fhs.shtml):
- [FHS 3 HTML (multi-page)](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)

## Ansible

The [Ansible document "Special Variables"](https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html) doesn't list the details of some of the special variables. Here are some concrete examples for reference:
- `hostvars`:
  - A dictionary/map with all the hosts in inventory and variables assigned to them.
  - [`hostvars.json`](./Ansible/hostvars.json)
- `groups`:
  - A dictionary/map with all the groups in inventory and each group has the list of hosts that belong to it.
  - [`groups.json`](./Ansible/groups.json)
- `group_names`:
  - List of groups the current host is part of.
  - [`group_names.json`](./Ansible/group_names.json)
- `inventory_hostname`:
  - The inventory name for the ‘current’ host being iterated over in the play.
  - [`inventory_hostname.json`](./Ansible/inventory_hostname.json)

## Python

### Install in "Development Mode"

Link: [Working in "development mode"](https://packaging.python.org/guides/distributing-packages-using-setuptools/#working-in-development-mode)

- `python -m pip install -e .` where `.` is the root of the project directory (that has `setup.py`).
- `pip3 install -e .`

### Built-in Exceptions

Link: [Built-in exceptions](https://docs.python.org/3/library/exceptions.html)

```
BaseException
 +-- SystemExit
 +-- KeyboardInterrupt
 +-- GeneratorExit
 +-- Exception
      +-- StopIteration
      +-- StopAsyncIteration
      +-- ArithmeticError
      |    +-- FloatingPointError
      |    +-- OverflowError
      |    +-- ZeroDivisionError
      +-- AssertionError
      +-- AttributeError
      +-- BufferError
      +-- EOFError
      +-- ImportError
      |    +-- ModuleNotFoundError
      +-- LookupError
      |    +-- IndexError
      |    +-- KeyError
      +-- MemoryError
      +-- NameError
      |    +-- UnboundLocalError
      +-- OSError
      |    +-- BlockingIOError
      |    +-- ChildProcessError
      |    +-- ConnectionError
      |    |    +-- BrokenPipeError
      |    |    +-- ConnectionAbortedError
      |    |    +-- ConnectionRefusedError
      |    |    +-- ConnectionResetError
      |    +-- FileExistsError
      |    +-- FileNotFoundError
      |    +-- InterruptedError
      |    +-- IsADirectoryError
      |    +-- NotADirectoryError
      |    +-- PermissionError
      |    +-- ProcessLookupError
      |    +-- TimeoutError
      +-- ReferenceError
      +-- RuntimeError
      |    +-- NotImplementedError
      |    +-- RecursionError
      +-- SyntaxError
      |    +-- IndentationError
      |         +-- TabError
      +-- SystemError
      +-- TypeError
      +-- ValueError
      |    +-- UnicodeError
      |         +-- UnicodeDecodeError
      |         +-- UnicodeEncodeError
      |         +-- UnicodeTranslateError
      +-- Warning
           +-- DeprecationWarning
           +-- PendingDeprecationWarning
           +-- RuntimeWarning
           +-- SyntaxWarning
           +-- UserWarning
           +-- FutureWarning
           +-- ImportWarning
           +-- UnicodeWarning
           +-- BytesWarning
           +-- ResourceWarning
```

## SSH

- Remove a known (but out-dated) host key: `ssh-keygen -f "/home/ywen/.ssh/known_hosts" -R "10.0.0.10"`.
- Sign a certificate: `ssh-keygen -s <path-to-CA-private-key> -I <identity> -n <principal> -V +1w -z <serial-no> <path-to-user-public-key>`
  - Example: `ssh-keygen -s ~/my_ca/private.key -I ywen-m4800 -n root-everywhere -V +1w -z 4800 "$HOME/.ssh/id_ecdsa.pub"`.
