---
comments: true
date: 2022-10-05
layout: post
tags: [Tech,Cloud]
title: A quick review of Fluentd
---

I find it a bit challenging to follow [Fluentd documentation](https://docs.fluentd.org/), so this article is a guideline of "how to use Fluentd documentation". This article assumes the readers (most likely, me myself) already have some experience in using Fluentd.

## 1. Fluentd vs td-agent vs Fluent Bit

In summary:
- They are all data collector for building the unified logging layer.
- `Fluentd` is the open-source, community-driven version.
- `td-agent` is the stable distribution of Fluentd, maintained by Treasure Data, Inc.
- `Fluent Bit` is for "constraint environments like Embedded Linux and Gateways."

See:
- [Fluentd: Frequently Asked Questions](https://www.fluentd.org/faqs)
- [A Brief History of Fluent Bit](https://docs.fluentbit.io/manual/about/history)

## 2. Documentation

First of all, its [1] [Overview](https://docs.fluentd.org/quickstart) page has a 3-step guideline of how to learn and use Fluentd.

Also check out the [2] [Architecture](https://www.fluentd.org/architecture) page.

The page [3] [Life of a Fluentd event](https://docs.fluentd.org/quickstart/life-of-a-fluentd-event) lets you understand how an event is handled and gives a big picture.

The section [4] [Configuration](https://docs.fluentd.org/configuration/) gives you details about how to configure Fluentd.

## 3. Understanding Fluentd

### 3.1 Essence

`Fluentd` uses a plug-in design to aggregate many different types of log **inputs**, **transformers**, and **outputs**.

The most simple configuration is:

```
input -> filter -> output
```

### 3.2 Directives in configuration files

Inputs are configured by `<source>`. Transformers are configured by `<filter>`. Outputs are configured by `<match>`.

This defines a single **route** for processing incoming logs. However, on a complicated system, one route may not be enough. The users will want to define **multiple routes** for different kinds of logs. The ability of defining multiple routes is implemented by the `<label>` directive. See [5. Group filter and output: the "label" directive](https://docs.fluentd.org/configuration/config-file#5.-group-filter-and-output-the-label-directive) for an example.

The other configuration directives that [4] lists are:
- `<system>`: Set system-wide configuration.
- `<worker>`: Limit to the specific workers.
- `@include`: Include other files.

### 3.3 Plugins

Fluentd has the following types of plugins:

| Type | Used in | Description | Examples |
|:----:|:-------:|:------------|:---------|
| Input | `<source>` | Implement a new type of input. | `in_tail`, `in_forward`, `in_syslog` |
| Parser | `<source>` | Customize the input format parsing. | `regexp`, `apache2`, `syslog` |
| Filter | `<filter>` | Implement a new type of filter. | `grep`, `record_transformer`, `filter_stdout` |
| Output | `<match>` | Implement a new type of output. | `out_copy`, `out_null`, `out_s3` |
| Formatter | `<match>` | Customize the output format. | `json`, `csv`, `msgpack` |
| Storage | `<source>`<br/>`<filter>`<br/>`<match>` | For any plugin that needs to store internal state in memory or external storage. | `local` |
| Service Discovery | Any plugin that supports <br/> `<service_discovery>` | Some plugins, such as `out_forward`, use other services thus support service discovery. ||
| Buffer | `<match>` | Implement a customized buffer for output plugins. | `buf_memory`, `buf_file` |
| Metrics |  `<source>`<br/>`<filter>`<br/>`<match>` | Save its internal metrics in memory, influxdb or prometheus format ready in instances. | `local` |
