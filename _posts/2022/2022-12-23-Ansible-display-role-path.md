---
comments: true
date: 2022-12-23
layout: post
tags: [Tech,Ansible]
title: "Ansible: How to display a role's path"
---

When we debug a playbook, sometimes we want to figure out the actual path of the role in the playbook. As of `v2.9.12`, there doesn't seem to be a CLI option of `ansible` or `ansible-playbook` to show the role paths. But there are two other methods to do it.

The first method uses the debug output: Run [`export ANSIBLE_DEBUG=1`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#envvar-ANSIBLE_DEBUG) to enable debugging output. Then look for the debug log messages **"Loading data from"**:

```
 15267 1639582174.41790: Loading data from /home/ywen/ansible/roles/demo/defaults/main.yml
 15267 1639582174.41857: Loading data from /home/ywen/ansible/roles/demo/tasks/main.yml
```

The second method is to hack the code (assuming `v2.9.27`):
- `sudo vim /usr/lib/python2.7/dist-packages/ansible/playbook/role/definition.py`
- Find the following block (which should be line 90 ~ 94):

```python
        # first we pull the role name out of the data structure,
        # and then use that to determine the role path (which may
        # result in a new role name, if it was a file path)
        role_name = self._load_role_name(ds)
        (role_name, role_path) = self._load_role_path(role_name)
```

- Add a line of `display.v(...` right below the `_load_role_path` line:

```python
        (role_name, role_path) = self._load_role_path(role_name)
        display.v("Found role '{n}' at '{p}'".format(n=role_name, p=role_path))
```

- Running `ansible-playbook -v` (or any verbosity higher than `-v`) will print the used role path:

```
TASK [Task description] *********************************************************************************************************
Found role 'demo' at '/home/ywen/ansible/roles/demo'
```
