---
comments: true
date: 2024-08-05
layout: post
tags: [Tech,Ansible]
title: "Ansible: Understanding how a loop gets the items"
---

In this article, we use the following Ansible task for analysis:

```yaml
- name: Demo how to pass a list of strings using `--extra-vars` on the command line.
  gather_facts: no
  hosts: all
  tasks:
    - name: Print a string.
      debug:
        msg: "string: {{item}}"
      loop: "{{str_list}}"
```

Suppose the `ansible-playbook` command line is as follows:

```
ansible-playbook -v -e str_list='["abc","def"]' ./cli-extra-vars-list.yml
```

For an Ansible task (e.g., the task "Print a string" in the example above) that loops over a list of items, the code that obtains the items for the loop is in [the method `_get_loop_items` in the file `lib/ansible/executor/task_executor.py`](https://github.com/ansible/ansible/blob/v2.9.12/lib/ansible/executor/task_executor.py#L192):

```python
    def _get_loop_items(self):
        '''
        Loads a lookup plugin to handle the with_* portion of a task (if specified),
        and returns the items result.
        '''

        # ... (other code)
        if loop_cache is not None:
            # This branch uses loop cache.

        elif self._task.loop_with:
            # This branch is for the legacy `loop_with`.

        elif self._task.loop is not None:
            # This branch is for the modern `loop`.

        # ... (other code)

        return items
```

The object `self._task.loop` is an object of [`ansible.parsing.yaml.objects.AnsibleUnicode`](https://github.com/ansible/ansible/blob/v2.9.12/lib/ansible/parsing/yaml/objects.py#L61), and its string representation is `{{str_list}}`.

The branch for `self._task.loop` has the following code:

```python
        # ... (other code)

        from ansible.template import Templar

        # ... (other code)

        templar = Templar(loader=self._loader, shared_loader_obj=self._shared_loader_obj, variables=self._job_vars)

        # ... (other code)

        if loop_cache is not None:
          # This branch uses loop cache.

        elif self._task.loop_with:
            # This branch is for the legacy `loop_with`.

        elif self._task.loop is not None:
            items = templar.template(self._task.loop)
            if not isinstance(items, list):
                raise AnsibleError(
                    "Invalid data passed to 'loop', it requires a list, got this instead: %s."
                    " Hint: If you passed a list/dict of just one element,"
                    " try adding wantlist=True to your lookup invocation or use q/query instead of lookup." % items
                )

        # ... (other code)
```

So Ansible calls `templar.template` to instantiate the template string into a list of items, and the object `templar` is an instance of `Templar` which is imported from the module `ansible.template`.

[The method `templar.template`](https://github.com/ansible/ansible/blob/v2.9.12/lib/ansible/template/__init__.py#L522) looks like the following:

```python
    def template(self, variable, convert_bare=False, preserve_trailing_newlines=True, escape_backslashes=True, fail_on_undefined=None, overrides=None,
                 convert_data=True, static_vars=None, cache=True, disable_lookups=False):
        '''
        Templates (possibly recursively) any given data as input. If convert_bare is
        set to True, the given data will be wrapped as a jinja2 variable ('{{foo}}')
        before being sent through the template engine.
        '''

        # ... (other code)

            if isinstance(variable, string_types):
                # If the given variable is a template string. For example:
                # loop: "{{str_list}}"

                # ... (other code)
            elif isinstance(variable, (list, tuple)):
                # If the given variable is a list. For example:
                # loop:
                #   - value1
                #   - value2

                # ... (other code)
            elif isinstance(variable, (dict, Mapping)):
                # If the given variable is an object. For example:
                # loop:
                #   - k1: v1
                #   - k2: v2

                # ... (other code)
            else:
                return variable

            # ... (other code)
```

In the case of the example, `variable` is of the type in `string_types`, so the first `if` branch is executed to convert the template string `{{str_list}}` into a list of items.

After the method `templar.template` returns, we need to further check if the returned items are actually a list. If not, the error `Invalid data passed to 'loop'` will be raised.
