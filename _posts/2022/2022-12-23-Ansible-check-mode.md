---
comments: true
date: 2022-12-23
layout: post
tags: [Tech,Ansible]
title: "Ansible: How `check_mode` is set"
---

## 1. Overview

In general, there are (at least) two ways of setting `check_mode`:

- 1). Use the option `--check` on the command line (e.g., `ansible-playbook --check` or `ansible --check`).
- 2). Set `_ansible_check_mode` in `ANSIBLE_MODULE_ARGS`.

But the first method will (probably) eventually use the second method, because an Ansible module is not executed directly, but firstly packed into an `AnsibleZ` tarball (the input arguments included) and then sent to the target machine to run.

## 2. Loading the CLI option variables into `VariableManager`

[`lib/ansible/vars/manager.py`](https://github.com/yaobinwen/ansible/blob/v2.9.27/lib/ansible/vars/manager.py) has the class `VariableManager`. `VariableManager.__init__` calls `load_options_vars()` to load option variables in `self._options_vars = load_options_vars(version_info)`:

```python
def load_options_vars(version):

    if version is None:
        version = 'Unknown'
    options_vars = {'ansible_version': version}
    attrs = {'check': 'check_mode',
             'diff': 'diff_mode',
             'forks': 'forks',
             'inventory': 'inventory_sources',
             'skip_tags': 'skip_tags',
             'subset': 'limit',
             'tags': 'run_tags',
             'verbosity': 'verbosity'}

    for attr, alias in attrs.items():
        opt = context.CLIARGS.get(attr)
        if opt is not None:
            options_vars['ansible_%s' % alias] = opt

    return options_vars
```

## 3. `ansible_check_mode` is returned by `VariableManager.get_vars()`

`ansible_check_mode` is returned by `VariableManager._get_magic_variables()` in the "Set options vars" part (near the end of the function):

```python
        # Set options vars
        for option, option_value in iteritems(self._options_vars):
            variables[option] = option_value
```

In `VariableManager.get_vars()`, the magic variables are combined into `all_vars`: `all_vars = combine_vars(all_vars, magic_variables)`.

## 4. All the variables in `VariableManager` are loaded into `task_vars` in the strategy

[`TaskQueueManager`](https://github.com/yaobinwen/ansible/blob/v2.9.27/lib/ansible/executor/task_queue_manager.py#L260-L282) is eventually used to run the Ansible tasks.

`TaskQueueManager.run()` loads the strategy and call the strategy's `run()` method: `play_return = strategy.run(iterator, play_context)`. By default, the strategy is the `linear` strategy.

In `linear.StrategyModule.run()`, the variables are loaded into `task_vars`:

```python
task_vars = self._variable_manager.get_vars(
    play=iterator._play, host=host, task=task,
    _hosts=self._hosts_cache, _hosts_all=self._hosts_cache_all
)
```

## 5. `task_vars` are passed into the worker process

Then `task_vars` are passed into `self._queue_task(host, task, task_vars, play_context)`.

In `StrategyBase._queue_task()`, `task_vars` are passed into `WorkerProcess`: ` worker_prc = WorkerProcess(self._final_q, task_vars, host, task, play_context, self._loader, self._variable_manager, plugin_loader)`.

In `WorkerProcess.__init__()`, `task_vars` are recorded in `self._task_vars`. In `WorkerProcess._run()`, `self._task_vars` are passed into `TaskExecutor` as its `job_vars`:

```python
            executor_result = TaskExecutor(
                self._host,
                self._task,
                self._task_vars,
                self._play_context,
                self._new_stdin,
                self._loader,
                self._shared_loader_obj,
                self._final_q
            ).run()
```

## 6. `TaskExecutor` passes the variables to the (normal) action plugin

`TaskExecutor.run()` calls `TaskExecutor._execute()` without setting `variables` (L147): `res = self._execute()`.

So `TaskExecutor._execute()` uses `self._job_vars` as `variables`:

```python
        if variables is None:
            variables = self._job_vars
```

`TaskExecutor._execute()` then runs `self._play_context = self._play_context.set_task_and_variable_override(task=self._task, variables=variables, templar=templar)` to override variables if needed.

Finally, `TaskExecutor._execute()` runs the handler (which is an action plugin) to run the module: `result = self._handler.run(task_vars=variables)`. `self._handler = self._get_action_handler(connection=self._connection, templar=templar)` which in the default case the `normal` handler that's defined in [`lib/ansible/plugins/action/normal.py`](https://github.com/yaobinwen/ansible/blob/v2.9.27/lib/ansible/plugins/action/normal.py).

## 7. `normal` action plugin updates the module arguments

The `normal` action plugin calls `ActionBase._execute_module()` to run the module. `ActionBase._execute_module()` runs `self._update_module_args(module_name, module_args, task_vars)` to update the module's arguments.

`ActionBase._update_module_args()`:

```python
        # set check mode in the module arguments, if required
        if self._play_context.check_mode:
            if not self._supports_check_mode:
                raise AnsibleError("check mode is not supported for this operation")
            module_args['_ansible_check_mode'] = True
        else:
            module_args['_ansible_check_mode'] = False
```

OK, so now `module_args` has `_ansible_check_mode` set.

## 8. `normal` action plugin executes the module

But note that the Ansible module is packed up into an `AnsibleZ` tarball together with the arguments and sent to the target machine to run. On the target machine, the module's `run_module()` function is called.

Typically, inside `run_module()`, `AnsibleModule` is instantiated. `AnsibleModule.__init__()` calls `AnsibleModule._check_arguments()` which does the following:

```python
        for k in PASS_VARS:
            # handle setting internal properties from internal ansible vars
            param_key = '_ansible_%s' % k
            if param_key in param:
                if k in PASS_BOOLS:
                    setattr(self, PASS_VARS[k][0], self.boolean(param[param_key]))
                else:
                    setattr(self, PASS_VARS[k][0], param[param_key])

                # clean up internal top level params:
                if param_key in self.params:
                    del self.params[param_key]
            else:
                # use defaults if not already set
                if not hasattr(self, PASS_VARS[k][0]):
                    setattr(self, PASS_VARS[k][0], PASS_VARS[k][1])
```

where `PASS_VARS` contains `check_mode`:

```python
PASS_VARS = {
    'check_mode': ('check_mode', False),
    # ...
}
```

For `AnsibleModule._check_arguments(self, check_invalid_arguments, spec=None, param=None, legal_inputs=None)`, when `param` is `None`:

```python
        if param is None:
            param = self.params
```

`self.params` is set in `def _load_params(self)`:

```python
    def _load_params(self):
        ''' read the input and set the params attribute.

        This method is for backwards compatibility.  The guts of the function
        were moved out in 2.1 so that custom modules could read the parameters.
        '''
        # debug overrides to read args from file or cmdline
        self.params = _load_params()
```

`_load_params()` eventually only returns `params['ANSIBLE_MODULE_ARGS']`. So if I want to override any `ansible_*` variable, I can include it in `params['ANSIBLE_MODULE_ARGS']` as `_ansible_*` (note there must be the leading underscore `_`). For example:

```python
{
    "ANSIBLE_MODULE_ARGS": {
        "_ansible_check_mode": True,
    }
}
```

See [`demo/ansible/roles/unittest-module/library/test_my_test.py`](https://github.com/yaobinwen/robin_on_rails/blob/master/Ansible/demo/ansible/roles/unittest-module/library/test_my_test.py) for an example.
