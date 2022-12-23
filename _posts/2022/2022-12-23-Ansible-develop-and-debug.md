---
comments: true
date: 2022-12-23
layout: post
tags: [Tech,Ansible]
title: "Ansible: Develop and Debug"
---

## 1. Overview

This article is my notes about how to develop and debug Ansible. The latest version (i.e., the `devel` version) of Ansible's developer guide is here: [_Developer Guide_](https://docs.ansible.com/ansible/devel/dev_guide/index.html). Note that Ansible may re-organize their documentation site so the links may become broken. Should this happen, search the key word "Ansible Developer Guide" in Google.

## 2. References

This article uses the following references:
- [1] [Developing Ansible modules](https://docs.ansible.com/ansible/devel/dev_guide/developing_modules_general.html)
  - [1.1] [Preparing an environment for developing Ansible modules](https://docs.ansible.com/ansible/devel/dev_guide/developing_modules_general.html#preparing-an-environment-for-developing-ansible-modules)
  - [1.2] [Creating an info or a facts module](https://docs.ansible.com/ansible/devel/dev_guide/developing_modules_general.html#creating-an-info-or-a-facts-module)
  - [1.3] [Creating a module](https://docs.ansible.com/ansible/devel/dev_guide/developing_modules_general.html#creating-a-module)

## 3. Prepare Development Environment to Develop a Module

The development environment preparation is part of a larger scenario: Developing Ansible modules [1]. To prepare the development environment, refer to [1.1]. The main steps are as follows (assuming Ubuntu):

- 1). Install prerequisites:
  - The Debian packages:
    - build-essential
    - libssl-dev
    - libffi-dev
    - python-dev
    - python3-dev
    - python3-venv
- 2). Clone the Ansible repository: `$ git clone https://github.com/ansible/ansible.git`
- 3). Change directory into the repository root dir: `$ cd ansible`
- 4). Create a virtual environment:
  - `$ python3 -m venv venv` (or for Python 2 `$ virtualenv venv`. Note, this requires you to install the `virtualenv` package: `$ pip install virtualenv`)
- 5). Activate the virtual environment: `$ . venv/bin/activate`
- 6). Install development requirements: `$ pip install -r requirements.txt`
  - Make sure to upgrade `pip`: `pip install --upgrade pip` because Ubuntu 18.04 provides `pip 9.0.1` which is too old.
  - May need to install `setuptools_rust` using the latest version of `pip`: `pip install setuptools_rust`.
- 7). Run the environment setup script for each new development shell process: `$ . hacking/env-setup`

After the initial setup above, every time you are ready to start developing Ansible you should be able to just run the following from the root of the Ansible repo: `$ . venv/bin/activate && . hacking/env-setup`.

## 4. Decide Module Type

[1] mentions three types of modules:

| Type | Filename | Description | Template |
|:----:|:--------:|:------------|:--------:|
| info | `*_info.py` | Gathers information on other objects or files. | See [1.2] |
| facts | `*_facts.py` | Gather information about the target machines. | See [1.2] |
| general-purpose | `*.py` | For other purposes other than information or facts gathering. | See [1.3] |

## 5. Testing the Module

[1] also talks about how to test the newly created module, such as sanity test and unit test. As a note says:

> Ansible uses `pytest` for unit testing.

Usually, one cannot test the `run_module()` function directly because it requires two things:
- `stdin` as `AnsibleModule` reads its input arguments from the standard input.
- `exit_json()` and `fail_json()` call `sys.exit()` which will cause the test program to exit.

Therefore, usually, one can only test the functions that the Ansible module calls. But the [`patch_ansible_module()` function](https://github.com/yaobinwen/ansible/blob/devel/test/units/modules/conftest.py#L16-L31) makes it possible to test the Ansible module directly:

```python
@pytest.fixture
def patch_ansible_module(request, mocker):
    if isinstance(request.param, string_types):
        args = request.param
    elif isinstance(request.param, MutableMapping):
        if 'ANSIBLE_MODULE_ARGS' not in request.param:
            request.param = {'ANSIBLE_MODULE_ARGS': request.param}
        if '_ansible_remote_tmp' not in request.param['ANSIBLE_MODULE_ARGS']:
            request.param['ANSIBLE_MODULE_ARGS']['_ansible_remote_tmp'] = '/tmp'
        if '_ansible_keep_remote_files' not in request.param['ANSIBLE_MODULE_ARGS']:
            request.param['ANSIBLE_MODULE_ARGS']['_ansible_keep_remote_files'] = False
        args = json.dumps(request.param)
    else:
        raise Exception('Malformed data to the patch_ansible_module pytest fixture')

    mocker.patch('ansible.module_utils.basic._ANSIBLE_ARGS', to_bytes(args))
```

Currently (as of 2022-12-23), the only tests that use `patch_ansible_module()` is [`test_pip.py`](https://github.com/yaobinwen/ansible/blob/devel/test/units/modules/test_pip.py).

## 6. Display Messages

Use the module [`lib/ansible/utils/display.py`](https://github.com/yaobinwen/ansible/blob/devel/lib/ansible/utils/display.py). Search the code `from ansible.utils.display import Display` or something similar to find the examples in the codebase. Typically, it is used in the way below:

```python
from ansible.utils.display import Display

display = Display()

display.error("error message")
display.vvvvv("verbose message")
```

## 7. Debug Output vs `debug` Module Output

The "debug output" can refer to two things in Ansible, so be specific when talking about "debug output".

The first one is the log messages that are printed out by [`Display.debug()` method](https://github.com/yaobinwen/ansible/blob/devel/lib/ansible/utils/display.py):

```python
class Display(metaclass=Singleton):

    # ...

    def debug(self, msg, host=None):
        if C.DEFAULT_DEBUG:
            if host is None:
                self.display("%6d %0.5f: %s" % (os.getpid(), time.time(), msg), color=C.COLOR_DEBUG)
            else:
                self.display("%6d %0.5f [%s]: %s" % (os.getpid(), time.time(), host, msg), color=C.COLOR_DEBUG)
```

These debugging log messages can be toggled by the [environment variable `ANSIBLE_DEBUG`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#envvar-ANSIBLE_DEBUG) and the color can be configured by [`ANSIBLE_COLOR_DEBUG`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#envvar-ANSIBLE_COLOR_DEBUG). For example:

```
ywen@ywen-Precision-7510:~$ export ANSIBLE_COLOR_DEBUG="bright yellow"
ywen@ywen-Precision-7510:~$ export ANSIBLE_DEBUG=1
ywen@ywen-Precision-7510:~$ ansible -m ping localhost
```

The second one is the output of the [`ansible.builtin.debug` module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/debug_module.html).
