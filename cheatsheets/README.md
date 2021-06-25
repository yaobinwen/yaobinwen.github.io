# Cheat Sheet

## FAL (Frequently Accessed Links)

[Linux: Filesystem Hierarchy Standard](https://refspecs.linuxfoundation.org/fhs.shtml):
- [FHS 3 HTML (multi-page)](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)

## Ansible

`ansible_facts` has [facts about the remote system](https://docs.ansible.com/ansible/latest/user_guide/playbooks_vars_facts.html#ansible-facts):
- Run `ansible <hostname> -m ansible.builtin.setup` to print the _raw_ information gathered for the remote system.
  - The raw information can be accessed directly, e.g., `"{{ansible_system}}"`.
  - It can be accessed via the variable `ansible_facts`, too: `{{ansible_facts.system}}` which is equivalent to `"{{ansible_system}}"`.
- Run `ansible <hostname> -m ansible.builtin.setup -a "filter=ansible_local"` to print just the information of the specified part.
- Click [`ansible_facts_raw.json`](./Ansible/ansible_facts_raw.json) to see a sample (from running `ansible.builtin.setup`).

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

## Git

### Git Configuration

Use `vim` as the editor: `git config --global core.editor "vim"`

Use the specified GPG key to sign the commits: `git config --global user.signingKey "0xA788F5525815CBC6DF91A36E851F38D2609E665D"  # use key's fingerprint`
- Then run `git commit -S ...` to sign the commit.

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

## Ubuntu

### List the default installed packages

See [this answer](https://askubuntu.com/a/48894/514711) for reference. The release server maintains the `.manifest` files that list all the installed packages. Follow the steps below to find these files:

1. Go to `http://releases.ubuntu.com/`.
2. Scroll down to the bottom of the page to see the list of folders for different releases.
3. Find the appropriate release, e.g., [`21.04`](http://releases.ubuntu.com/21.04/).
4. Scroll down to the bottom of the page to see the list of files.
5. The manifest files for Desktop and Server are [`ubuntu-21.04-desktop-amd64.manifest`](http://releases.ubuntu.com/21.04/ubuntu-21.04-desktop-amd64.manifest) and [`ubuntu-21.04-live-server-amd64.manifest`](http://releases.ubuntu.com/21.04/ubuntu-21.04-live-server-amd64.manifest), respectively.
