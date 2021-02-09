---
comments: true
date: 2021-02-08
layout: post
tags: [Tech]
title: "Ansible Vault: Understanding How to Use Multiple Passwords"
---

(This article was posted [as an answer here](https://devops.stackexchange.com/a/13332/23543).)

This afternoon I also struggled on this. I think I've understood it a little bit more so I'd like to share it. But I'm also new to Ansible Vault so what I say here may not be completely correct. I used [1] as my main source of learning.

## What May Have Confused You

[1] says a `vault ID` has the pattern `label@source`. But the symbol `@` delivers the meaning of "inside", "at", or "of" which makes people think a vault ID `test@password_file` means a line inside the file `password_file` with the label `test`.

**But this is the gotcha**: according to my test, the **entire content** in `password_file` is used as the password. In your example above, the password **you think** is "my_test_pass"; but the password **Ansible Vault sees** is `dev my_dev_pass\ntest my_test_pass\nprod my_prod_pass` (note the white spaces and the End-of-Lines).

Therefore, `test@file_path` does not select the line "my_test_pass". It actually means the following:

- At **encryption**, it means "use the entire content in `file_path` as the password to encrypt the given message and marks the result with the label `test`".
- At **decryption**, it means "use the entire content in `file_path` as the password to decrypt everything that is marked with the label `test`".

## Using Multiple Password Files

Therefore, if you want to use different password files, you need to do it this way:

- Create three files (I put them at different folders intentionally for demo): `~/pass_dev.txt`, `/tmp/pass_test.txt`, `./pass_prod.txt`.
- Put the passwords into the correct files. Example: `my_dev_pass` into `pass_dev.txt`.
- When you encrypt the file `my_dev_file.yml`, you have two options:
  - You can specify just one vault ID: `ansible-vault encrypt --vault-id dev@~/pass_dev.txt my_dev_file.yml`
  - You can specify multiple vault IDs but must also use `--encrypt-valut-id` to tell `ansible-vault` which one should actually be used to encrypt the file: `ansible-vault encrypt --vault-id dev@~/pass_dev.txt test@/tmp/pass_test.txt prod@./pass_prod.txt --encrypt-vault-id dev my_dev_file.yml`

When you need to decrypt some content, you may or may not know what password the content was encrypted with. In this case, you can pass in all the possible vault IDs: `ansible-vault decrypt dev@~/pass_dev.txt test@/tmp/pass_test.txt prod@./pass_prod.txt some_encrypted_file.yml`. And vault will automatically figure out which password to use. This is talked about [in this section of [1]](https://docs.ansible.com/ansible/latest/user_guide/vault.html#passing-multiple-vault-passwords).

This also explains why the `label` part is only used as a hint. In fact, you can pass in the vault IDs with completely wrong labels:

```
ansible-vault decrypt prod@~/pass_dev.txt dev@/tmp/pass_test.txt test@./pass_prod.txt some_encrypted_file.yml
```

And `ansible-vault` is still able to decrypt the file, because, essentially, `ansible-vault` uses the `label` as the hint to see which password should be tried first. If it doesn't succeed, it tries the other passwords.

But if you define the environment variable `ANSIBLE_VAULT_ID_MATCH`, `ansible-vault` will take the labels seriously and only try the passwords with matching labels, so the following will fail:

```
ANSIBLE_VAULT_ID_MATCH=1 ansible-vault decrypt prod@~/pass_dev.txt dev@/tmp/pass_test.txt test@./pass_prod.txt some_encrypted_file.yml
```

## Other Things in Your Question

I may not be completely correct in this part: I guess `ansible-vault` maintains an internal list of "currently available vault IDs". If no `--vault-id` is present on the command line, the only available vault ID is `default`. When `--vault-id` arguments are given, the `default` is overridden by whatever is provided.

Therefore, when you encrypted the target file using a `--vault-password-file`, without any other `--vault-id`, the only available vault ID was `default`. But by providing `--encrypt-vault-id=test` you were asking `ansible-vault` to encrypt the target file using a vault ID of "test" which was not available, hence the error "Did not find a match".

Later, when you provided `ansible-vault` with only `--vault-id abc@file_path` but asked it to encrypt the target file using `test`, `ansible-vault` still couldn't find the required vault ID, hence the error "Did not find a match" again.

You made the mistake because you thought `test@file_path` selects one password from all the available passwords in `file_path`, so by providing one password file, you thought you had provided multiple passwords. But that doesn't seem to be how `ansible-vault` works. You need to provide multiple password files (or, technically, multiple password sources which could also be prompts and scripts).

## References

- [1] Ansible 2.10 (latest as of 2021-02-08) [Encrypting content with Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
