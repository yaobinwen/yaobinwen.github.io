---
comments: true
date: 2022-07-03
layout: post
tags: [Tech,Linux,Ubuntu]
title: Locales on Ubuntu and how to set it in a Docker container
---

## What is a locale?

As [1] says:

> In computing, a locale is a set of parameters that defines the user's language, region and any special variant preferences that the user wants to see in their user interface. Usually a locale identifier consists of at least a language code and a country/region code.

## Locales on Ubuntu

Run `locale -a` to list all the available locales on the system:

```
$ locale -a
C
C.UTF-8
en_US.utf8
POSIX
```

Run `locale` to display the current settings:

```
$ locale
LANG=en_US.UTF-8
LANGUAGE=en_US
LC_CTYPE="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
LC_ALL=en_US.UTF-8
```

As [2] explains:
- `LANG` provides the "default value for `LC_*` variables that have not been explicitly set".
- `LC_ALL` "overrides individual `LC_*` settings: if `LC_ALL` is set, none of the below have any effect."

As [3] explains, `LC_*` are the environment variables "meant to override LANG and affecting a single locale category only".

[2] doesn't explain the purpose of `LANGUAGE`, but [3.1] explains:

> Not all programs have translations for all languages. By default, an English message is shown in place of a nonexistent translation. If you understand other languages, you can set up a priority **list** of languages. This is done through a different environment variable, called `LANGUAGE`.

Or, as [4] explains:

> The `LANGUAGE` environment variable can have one or more language values and is responsible for the order of the languages in which the messages will be displayed.

So if `LANGUAGE` is set to `fr_FR:en_EN`, French is preferred if the French translation is available, otherwise English is used. This is why we say `LANGUAGE` specifies a **priority list** of languages.

## The package `locales`

The package `locales` provides the utility `locale-gen`. If the locale you want to use does not appear in the list of `locale -a`, you can run `sudo locale-gen <locale-name>` to generate it:

```
$ sudo locale-gen en_US.UTF-8
[sudo] password for ywen:
Generating locales (this might take a while)...
  en_US.UTF-8... done
Generation complete.
```

The file `/usr/share/i18n/SUPPORTED` lists all the locales that can be generated.

`locales` also installs the utility `update-locale` which modifies `/etc/default/locale` to store the locale settings permanently:

```
$ sudo update-locale LANG=en_US.UTF-8
$ cat /etc/default/locale
#  File generated by update-locale
LANG=en_US.UTF-8
```

## Change locales for the current session

You can define/export the environment variables in the current session to change the locale settings for the current session. When you do this, note that `LANG` and `LC_ALL` may override the locale you are setting.

## Change locales permanently

`update-locale` can modify `/etc/default/locale` which is sourced into the current environment after a fresh login. `/etc/default/locale` is a system-wide setting. `$HOME/.pam_environment` is user-specific settings.

However, note that `$HOME/.pam_environment` is only effective when `UsePAM` is `yes` in `/etc/ssh/sshd_config`.

## Configure in a Docker container

You can include the following code in `Dockerfile` to configure the locales in a Docker container:

```dockerfile
ARG LOCALE="en_US.UTF-8"
ARG LANGUAGE="en_US"

# Generate and set the locale to UTF-8.
RUN locale-gen ${LOCALE}
ENV LANG ${LOCALE}
ENV LC_ALL ${LOCALE}
ENV LANGUAGE ${LANGUAGE}
```

## References

- [1] [Locale (computer software)](https://en.wikipedia.org/wiki/Locale_(computer_software))
- [2] [Ubuntu Community Wiki: Locale](https://help.ubuntu.com/community/Locale)
- [3] [GNU `gettext` utilities](https://www.gnu.org/software/gettext/manual/html_node/index.html)
  - [3.1] [2.3.3 Specifying a Priority List of Languages](https://www.gnu.org/software/gettext/manual/html_node/The-LANGUAGE-variable.html)
- [4] [Locale Environment Variables in Linux](https://www.baeldung.com/linux/locale-environment-variables)