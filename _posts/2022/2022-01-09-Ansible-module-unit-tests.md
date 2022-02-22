---
comments: true
date: 2022-01-09
layout: post
tags: [Tech]
title: "Ansible: How to unit test module without using `pytest`"
---

Ansible uses `pytest` for unit testing. Usually, one cannot test the `run_module()` function directly because it requires two things:
- `stdin` as `AnsibleModule` reads its input arguments from the standard input.
- `exit_json()` and `fail_json()` call `sys.exit()` which will cause the test program to exit.

Therefore, usually one can only test the functions that the Ansible module calls. But the [`patch_ansible_module()` function](https://github.com/yaobinwen/ansible/blob/devel/test/units/modules/conftest.py#L16-L31) makes it possible to test the Ansible module directly.

However, sometimes the project may not use `pytest` as the unit testing tool. Instead, the project may use Python's built-in `unittest` module. In this case, we wouldn't be able to use the function `patch_ansible_module()`.

But I implemented [this demo](https://github.com/yaobinwen/robin_on_rails/blob/master/Ansible/demo/ansible/roles/unittest-module/library/test_my_test.py) to show how to unit test an `AnsibleModule` in real mode and check mode using Python's `unittest` module. Basically,

- Implement `class MyAnsibleModule(AnsibleModuleBasic.AnsibleModule)` in order to change the behaviors of `exit_json()` and `fail_json()` so, when called, they don't actually quit the test program.
- Use `mock` to replace the real `AnsibleModule` with `MyAnsibleModule`.
- Set `_ansible_check_mode` in `ansible.module_utils.basic._ANSIBLE_ARGS` in order to use the check mode.

Go take a look at the code.
