---
comments: true
date: 2022-01-07
layout: post
tags: [Tech]
title: "Ansible: Understanding the `subelements` lookup (`with_subelements`)"
---

The document of `subelements` lookup [1] is not clear and has confused people [2]. In this article, I'm going to explain how it works. But also note that the `subelements` lookup can be replaced by `loop` and the `subelements` filter [3].

The key to understanding `with_subelements` is to firstly understand [_Cartesian product_](https://en.wikipedia.org/wiki/Cartesian_product):

> In mathematics, specifically set theory, the Cartesian product of two sets _A_ and _B_, denoted `A x B`, is the set of all ordered pairs (_a_, _b_) where _a_ is in _A_ and _b_ is in _B_.

For example, given two sets _A_ and _B_:

```
A = { 1, 2 }
B = { 3, 4, 5 }
```

The Cartesian product of A and B are: `(1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)`.

In Python, [`itertools.product`](https://docs.python.org/3/library/itertools.html#itertools.product) calculates the Cartesian product of input iterables (not limited to two input iterables). The example above can be implemented as follows:

```python
>>> import itertools
>>> A = set([1, 2])
>>> A
{1, 2}
>>> B = set([3, 4, 5])
>>> B
{3, 4, 5}
>>> list(itertools.product(A, B))
[(1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
>>>
```

`with_subelements` essentially calculates the Cartesian product of two lists. This is why it takes two input arguments. The special thing about `with_subelements` is: its second list is contained as a sub-element in the elements of the first list, hence the lookup name `with_subelements`. For example [2.1]:

```yaml
---
- hosts: localhost
  gather_facts: no
  vars:
    families:
      - surname: Smith
        country: US
        children:
          - name: Mike
            age: 4
          - name: Kate
            age: 7
      - surname: Sanders
        country: UK
        children:
          - name: Pete
            age: 12
          - name: Sara
            age: 17

  tasks:
    - name: List children
      debug:
        msg: "Family={{ item.0.surname }} Child={{ item.1.name }} Age={{ item.1.age }}"
      with_subelements:
        - "{{ families }}"
        - children
```

The first list is `families`; the second list is `children` which is a sub-element in every element of the first list. Therefore, `with_subelements` calculates the Cartesian product of the two lists and produces the following list of pairs:

```
[
  ({u'country': u'US', u'surname': u'Smith'}, {u'age': 4, u'name': u'Mike'}),
  ({u'country': u'US', u'surname': u'Smith'}, {u'age': 7, u'name': u'Kate'}),
  ({u'country': u'UK', u'surname': u'Sanders'}, {u'age': 12, u'name': u'Pete'}),
  ({u'country': u'UK', u'surname': u'Sanders'}, {u'age': 17, u'name': u'Sara'})
]
```

So the result messages are:

```
Family=Smith Child=Mike Age=4
Family=Smith Child=Kate Age=7
Family=Sanders Child=Pete Age=12
Family=Sanders Child=Sara Age=17
```

Refer to [subelements-lookup.yml](https://github.com/yaobinwen/robin_on_rails/blob/master/Ansible/demo/ansible/subelements-lookup.yml) to run the example code.

References:
- [1] [ansible.builtin.subelements – traverse nested key from a list of dictionaries](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/subelements_lookup.html)
- [2] [Stack Overflow: Ansible with_subelements](https://stackoverflow.com/q/41908715/630364)
  - [2.1] [Answer from Konstantin Suvorov](https://stackoverflow.com/a/41908853/630364)
- [3] [Migrating from with_X to loop: with_subelements](https://docs.ansible.com/ansible/latest/user_guide/playbooks_loops.html#with-subelements)
