---
comments: true
date: 2022-01-06
layout: post
tags: [Tech]
title: "Ansible: Add elements to list"
---

Today, I needed to convert the following list `config_original`

```yaml
config_original:
  - iface: "enx00e07cc85b6e"
    subnet: "192.168.16.0/24"
    netmask: "255.255.255.0"
    listen: "192.168.16.30"
    range:
      start: "192.168.16.1"
      end: "192.168.16.28"
    reserved:
      - "192.168.16.29"
  - iface: "enx241b7af8cdf1"
    subnet: "192.168.16.0/24"
    netmask: "255.255.255.0"
    listen: "192.168.16.60"
    range:
      start: "192.168.16.31"
      end: "192.168.16.58"
    reserved:
      - "192.168.16.59"
```

into the list `config_modified` as follows:

```yaml
config_modified:
  - iface: "enx00e07cc85b6e"
    dhcp: off
    subnet: "192.168.16.0/24"
    netmask: "255.255.255.0"
    static_ip_addresses:
      - "192.168.16.29"
    gateway: "192.168.16.1"
  - iface: "enx241b7af8cdf1"
    dhcp: off
    subnet: "192.168.16.0/24"
    netmask: "255.255.255.0"
    static_ip_addresses:
      - "192.168.16.59"
    gateway: "192.168.16.31"
```

Basically, for every entry in `config_original`, I needed to:
- Remove the element `listen` and `range`.
- Rename the field `reserved` to `static_ip_addresses`.
- Add the field `dhcp` and `gateway`.

I examined the following [filters](https://docs.ansible.com/ansible/latest/user_guide/playbooks_filters.html):
- `json_query`
- `subelements`
- Other JSON manipulation filters.

But none of them worked for me. JSONPath (as explained in [JSONPath - XPath for JSON](https://goessner.net/articles/JsonPath/index.html)) looks promising initially but:

- Only the data is selected and the key is missing, so the result is not a `key-value` pair. For example, when I tried the JSONPath expression `$..iface,subnet`, I got:

```json
[
  "enx00e07cc85b6e",
  "192.168.16.0/24",
  "enx241b7af8cdf1",
  "192.168.16.0/24"
]
```

- JSONPath doesn't seem to support renaming the key name, so I couldn't rename `reserved` to `static_ip_addresses`.

Inspired by [1] and [2], I figured out [the following playbook](https://github.com/yaobinwen/robin_on_rails/blob/master/Ansible/demo/ansible/add-element-to-list.yml) to do the conversion:

```yaml
- name: Demo how to add elements to a list.
  gather_facts: no
  hosts: all
  tasks:
    - name: Define the original data.
      set_fact:
        config_original:
          - iface: "enx00e07cc85b6e"
            subnet: "192.168.16.0/24"
            netmask: "255.255.255.0"
            listen: "192.168.16.30"
            range:
            start: "192.168.16.1"
            end: "192.168.16.28"
            reserved:
              - "192.168.16.29"
          - iface: "enx241b7af8cdf1"
            subnet: "192.168.16.0/24"
            netmask: "255.255.255.0"
            listen: "192.168.16.60"
            range:
            start: "192.168.16.31"
            end: "192.168.16.58"
            reserved:
              - "192.168.16.59"

    - name: Transform config_original to config_modified
      vars:
        config_modified: []
        config_entry:
          # `item` is re-evaluated in every iteration of the loop.
          iface: "{ {item.iface} }"
          dhcp: off
          subnet: "{ {item.subnet} }"
          netmask: "{ {item.netmask} }"
          static_ip_address: "{ {item.reserved} }"
          gateway: ~
      set_fact:
          config_modified: "{ {config_modified + [config_entry]} }"
      loop: "{ {config_original} }"

    - name: Display the final result.
      debug:
        var: config_modified
```

There are a few notes about the implementation:

- The variable `item` from `loop` can be used in a variable that's defined in `vars`. `item` is re-evaluated in every iteration of the loop so the value of the variable changes accordingly.
- The variable evaluation (`{ {var} }`) is Jinja2 evaluation which is essentially Python code. So `config_modified + [config_entry]` means "put `config_entry` into a list and use this list to extend the current `config_modified`". This is the key that `config_modified` gets extended instead of being overwritten.

The output of the `debug` task confirms the modification:

```
TASK [Display the final result.] ********************************
ok: [localhost] => 
  config_modified:
  - dhcp: false
    gateway: null
    iface: enx00e07cc85b6e
    netmask: 255.255.255.0
    static_ip_address:
    - 192.168.16.29
    subnet: 192.168.16.0/24
  - dhcp: false
    gateway: null
    iface: enx241b7af8cdf1
    netmask: 255.255.255.0
    static_ip_address:
    - 192.168.16.59
    subnet: 192.168.16.0/24
```

References:
- [1] [Ansible - Appending To Lists And Dictionaries](https://ttl255.com/ansible-appending-to-lists-and-dictionaries/)
- [2] [How to append to lists in Ansible](https://blog.crisp.se/2016/10/20/maxwenzin/how-to-append-to-lists-in-ansible)
