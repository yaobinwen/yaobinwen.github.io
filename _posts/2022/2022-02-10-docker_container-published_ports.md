---
comments: true
date: 2022-02-10
layout: post
tags: [Tech]
title: "Ansible: Why `docker_container`'s `published_ports` only binds IPv4 addresses by default?"
---

I'm using Ansible `2.9.27` (and the built-in `docker_container` module). But if you are using a newer version of Ansible and the collection `community.docker`, this article still applies.

Today I noticed that Docker's CLI command `docker run` and Ansible's module `docker_container` have different behaviors in publishing the ports.

Use the [Docker image `redis`](https://hub.docker.com/_/redis) as the example. By default, Redis listens to the port `6379` (as you can find it in its [quick start](https://redis.io/topics/quickstart)). When starting the container using `docker run`, if you publish this port specifically, the port will be published on both IPv4 and IPv6 addresses:

```
ywen@ywen-2018-02:~$ docker run --name some-redis --rm -p 6379 -d redis
ee5fcd61f93bf23e1d7dcb5d752b6ab9229e95c474060ad3e283c3ba7cadc260
ywen@ywen-2018-02:~$ docker port some-redis
6379/tcp -> 0.0.0.0:49192
6379/tcp -> :::49184
ywen@ywen-2018-02:~$
```

With the following playbook `d.yml`:

```yaml
- name: Create a Docker container `some-redis`.
  hosts: localhost
  connection: local
  tasks:
    - docker_container:
        name: some-redis-ansible
        image: redis:latest
        published_ports: ['6379']
```

the port will only be published to IPv4 addresses:

```
ywen@ywen-2018-02:~$ ansible-playbook d.yml 
ywen@ywen-2018-02:~$ docker port some-redis-ansible
6379/tcp -> 0.0.0.0:49195
ywen@ywen-2018-02:~$
```

The [`docker_container`'s `published_ports` document](https://docs.ansible.com/ansible/latest/collections/community/docker/docker_container_module.html#parameter-published_ports) has the following paragraph [1]:

> If _networks_ parameter is provided, will inspect each network to see if there exists a bridge network with optional parameter `com.docker.network.bridge.host_binding_ipv4`. If such a network is found, then published ports where no host IP address is specified will be bound to the host IP pointed to by `com.docker.network.bridge.host_binding_ipv4`. Note that the first bridge network with a `com.docker.network.bridge.host_binding_ipv4` value encountered in the list of networks is the one that will be used.

This description sort of explains why `docker run` and `docker_container` behave differently. I looked into the code of `docker_container` [2] to confirm the understanding.

The field `published_ports` is parsed [here](https://github.com/ansible/ansible/blob/v2.9.27/lib/ansible/modules/cloud/docker/docker_container.py#L1284):

```python
        self.published_ports = self._parse_publish_ports()
```

The code of the method `_parse_publish_ports()` is [here](https://github.com/ansible/ansible/blob/2685efe544c500bc5b2e3cbb0d7d594b7c81273b/lib/ansible/modules/cloud/docker/docker_container.py#L1578-L1627):

```python
    def _parse_publish_ports(self):
        '''
        Parse ports from docker CLI syntax
        '''
        if self.published_ports is None:
            return None

        if 'all' in self.published_ports:
            return 'all'

        default_ip = self.default_host_ip

        binds = {}
        for port in self.published_ports:
            parts = split_colon_ipv6(to_text(port, errors='surrogate_or_strict'), self.client)
            container_port = parts[-1]
            protocol = ''
            if '/' in container_port:
                container_port, protocol = parts[-1].split('/')
            container_ports = parse_port_range(container_port, self.client)

            p_len = len(parts)
            if p_len == 1:
                port_binds = len(container_ports) * [(default_ip,)]
            elif p_len == 2:
                port_binds = [(default_ip, port) for port in parse_port_range(parts[0], self.client)]
            elif p_len == 3:
                # We only allow IPv4 and IPv6 addresses for the bind address
                ipaddr = parts[0]
                if not re.match(r'^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$', parts[0]) and not re.match(r'^\[[0-9a-fA-F:]+\]$', ipaddr):
                    self.fail(('Bind addresses for published ports must be IPv4 or IPv6 addresses, not hostnames. '
                               'Use the dig lookup to resolve hostnames. (Found hostname: {0})').format(ipaddr))
                if re.match(r'^\[[0-9a-fA-F:]+\]$', ipaddr):
                    ipaddr = ipaddr[1:-1]
                if parts[1]:
                    port_binds = [(ipaddr, port) for port in parse_port_range(parts[1], self.client)]
                else:
                    port_binds = len(container_ports) * [(ipaddr,)]

            for bind, container_port in zip(port_binds, container_ports):
                idx = '{0}/{1}'.format(container_port, protocol) if protocol else container_port
                if idx in binds:
                    old_bind = binds[idx]
                    if isinstance(old_bind, list):
                        old_bind.append(bind)
                    else:
                        binds[idx] = [old_bind, bind]
                else:
                    binds[idx] = bind
        return binds
```

According to the code, if no IP address is specified, the `default_ip` is used. `default_ip` gets its value from [`self.default_host_ip`](https://github.com/ansible/ansible/blob/2685efe544c500bc5b2e3cbb0d7d594b7c81273b/lib/ansible/modules/cloud/docker/docker_container.py#L1558-L1576) which is a `@property`:

```python
    @property
    def default_host_ip(self):
        ip = '0.0.0.0'
        if not self.networks:
            return ip
        for net in self.networks:
            if net.get('name'):
                try:
                    network = self.client.inspect_network(net['name'])
                    if network.get('Driver') == 'bridge' and \
                       network.get('Options', {}).get('com.docker.network.bridge.host_binding_ipv4'):
                        ip = network['Options']['com.docker.network.bridge.host_binding_ipv4']
                        break
                except NotFound as nfe:
                    self.client.fail(
                        "Cannot inspect the network '{0}' to determine the default IP: {1}".format(net['name'], nfe),
                        exception=traceback.format_exc()
                    )
        return ip
```

The code shows that if `networks` (which is a field of `docker_container`) is not specified, which is my case in the simple playbook above, only the IPv4 address `0.0.0.0` is used. This explains why `docker_container` only publishes the port on IPv4 addresses in my simple playbook example.

## Notes

- [1] The document for `docker_container` in Ansible 2.9.27 is [here](https://docs.ansible.com/ansible/2.9/modules/docker_container_module.html#docker-container-module).
- [2] The code of the collection `community.docker` can be found at [ansible-collections/community.docker](https://github.com/ansible-collections/community.docker). The code of `docker_container` module in Ansible 2.9.27 can be found at [ansible/ansible](https://github.com/ansible/ansible/blob/v2.9.27/lib/ansible/modules/cloud/docker/docker_container.py).
