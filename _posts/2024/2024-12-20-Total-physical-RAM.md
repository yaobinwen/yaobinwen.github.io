---
comments: true
date: 2024-12-20
layout: post
tags: [Tech,ubuntu]
title: "How to get the total physical RAM on Ubuntu: sounds easy, but not really"
---

## 1. Sounds like an easy task.

Today, I needed to implement a small piece of code to get the total amount of the physical RAM counted in `GB` on my machine. A quick Google search told me that I could get it by reading the field `MemTotal` in the file `/proc/meminfo`:

```
MemTotal:       65797108 kB
MemFree:        45274684 kB
MemAvailable:   60898056 kB
...
```

A simple `awk` command can do it:

```
$ awk '/MemTotal/ {printf "%.0f\n", $2 / (1024 * 1024)}' /proc/meminfo
```

In this `awk`, `$2` was the number `65797108` in the unit of `kB`, thus `(1024 * 1024)` converted it to `GB`. `%.0f` made sure the decimal part of the result would be rounded up or down to the nearest integer. The result was `63` which was close to the actual 64 GB of physical RAM on my machine. Sounds an easy task, right? But as I investigated further, this project turned out to be more complicated than I thought.

## 2. Isn't `kB` to the powers of 10?

I noticed that the units in `/proc/meminfo` were all `kB`. According to Wikipedia, `kB` represents 1000 bytes:

> The [International System of Units (SI)](https://en.wikipedia.org/wiki/International_System_of_Units) defines the prefix _kilo_ as a multiplication factor of `1000` ($10^3$); therefore, one kilobyte is 1000 bytes.

If this is true, then I would have used `(1000 * 1000)` to convert the `MemTotal` value to GB. However, when I checked the result from `free`, I saw `free` reported the same amount of total memory:

```
$ free 
              total        used        free      shared  buff/cache   available
Mem:       65797108     5945032    42368604       90780    17483472    59129968
Swap:       2097148           0     2097148
```

And according to `free(1)`, everything is reported in kibibytes by default:

>        -k, --kibi
>             Display the amount of memory in kibibytes.  This is the default.

Therefore, `(1024 * 1024)` was the right conversion to use. But I still wanted to confirm that `/proc/meminfo` uses kibibytes as the unit.

[This post](https://superuser.com/a/1737658) looks into the kernel code to confirm that `/proc/meminfo` reports everything in kibibytes even if the units were written in `kB`:

> ... the kernel internally counts memory in terms of free pages (which are typically 4k or 16k but always power-of-two) and its `show_val_kb()` function uses a bit shift operation (which is equivalent to a multiplication by power-of-two, producing binary units again) to convert the page count into a kilobyte value:
>
> ```c
> static void show_val_kb(struct seq_file *m, const char *s, unsigned long num)
> {
>         seq_put_decimal_ull_width(m, s, num << (PAGE_SHIFT - 10), 8);
>         seq_write(m, " kB\n", 4);
> }
> ```

The function `show_val_kb()` can be found in [`linux/fs/proc/meminfo.c`](https://github.com/torvalds/linux/blob/master/fs/proc/meminfo.c).

In fact, there was an [email thread "[RFC] proc: meminfo: Replace kB with KiB in output"](https://lore.kernel.org/lkml/1460301791-15645-1-git-send-email-alexj@linux.com/) that asked "the reason what the output is as it is." Then Alexandru Juncu submitted a patch in the email ["[PATCH] proc: meminfo: Replace kB with KiB in output"](https://lore.kernel.org/lkml/1460301791-15645-2-git-send-email-alexj@linux.com/) to fix it. However, Andy Shevchenko [replied](https://lore.kernel.org/lkml/CAHp75Vf__Cb2=TDQRF4R5q8bfAQev2-smcdEMWz32MvYjGnT0Q@mail.gmail.com/) and said:

> I'm pretty sure you will get NAK for that. Obvious reason — `procfs` is ABI of the kernel. "We won't break userspace."

The conclusion is: `MemTotal` (and all the other fields in `/proc/meminfo`) was in the unit of kibibytes even though the output says `kB`. It remained unchanged in order to maintain backward compatibility to avoid breaking userspace programs.

## 3. Where is my 64th GiB of RAM?

The `awk` calculation result was 63 GiB. However, I know my machine had 64 GiB of RAM. Where is the 64th GiB?

It turned out to be that `MemTotal`, per `proc(5)`, is only the total usable RAM:

>               MemTotal %lu
>                    Total usable RAM (i.e., physical RAM minus a few reserved bits and the kernel binary code).

So the discrepancy between `MemTotal` and the actual physical RAM was caused by the RAM that kernel reserves. So my question became: What can tell me either the total amount of the physical RAM or the amount of RAM that kernel reserves?

This Stack Overflow post [_How can I find out the total physical memory (RAM) of my linux box suitable to be parsed by a shell script?_](https://stackoverflow.com/q/20348007) provides a lot of ideas.

### 3.1 Use `dmidecode`

`sudo dmidecode -t memory` can list all the available RAM:

```
# dmidecode 3.1
Getting SMBIOS data from sysfs.
SMBIOS 3.0.0 present.

Handle 0x0048, DMI type 16, 23 bytes
Physical Memory Array
	Location: System Board Or Motherboard
	Use: System Memory
	Error Correction Type: None
	Maximum Capacity: 64 GB
	Error Information Handle: Not Provided
	Number Of Devices: 4

Handle 0x0049, DMI type 17, 40 bytes
Memory Device
	...
	Size: 16384 MB
	...

Handle 0x004A, DMI type 17, 40 bytes
Memory Device
	...
	Size: 16384 MB
	...

Handle 0x004B, DMI type 17, 40 bytes
Memory Device
	...
	Size: 16384 MB
	...

Handle 0x004C, DMI type 17, 40 bytes
Memory Device
	...
	Size: 16384 MB
  ...
```

We should skip "Physical Memory Array" because that is for the available memory slots, not the actual physical memory installed.

We can use the `Size` field in the `Memory Device` entries to calculate the total installed physical memory. For my machine, the total physical memory is $16384 MB + 16384 MB + 16384 MB + 16384 MB = 65536 MB = 64 GiB$. (`dmidecode` reports sizes to the powers of 2.)

Unfortunately, `dmidecode` doesn't seem to support reporting results in any machine-readable format. People have been asking for that (see the email thread [_[dmidecode] Question: YAML and/or JSON output support_](https://lists.gnu.org/archive/html/dmidecode-devel/2020-01/msg00001.html)), but the development team said no. However, Kelly Brazil implemented a tool called [`jc`](https://github.com/kellyjonbrazil/jc) that "converts the output of popular command-line tools, file-types, and common strings to JSON, YAML, or Dictionaries." I haven't checked it out by myself, but it looks like a powerful tool. Another reason I didn't check it out was because the `lsmem` tool that I'm going to talk about below can report the total physical RAM in the machine-readable format JSON.

### 3.2. Use online memory blocks under `/sys/devices/system/memory`

[This answer](https://stackoverflow.com/a/53186875/630364) suggests using the online memory blocks to calculate the total physical memory.

```shell
totalmem=0;
for mem in /sys/devices/system/memory/memory*; do
  [[ "$(cat ${mem}/online)" == "1" ]] \
    && totalmem=$((totalmem+$((0x$(cat /sys/devices/system/memory/block_size_bytes)))));
done

echo ${totalmem} bytes
echo $((totalmem/1024**3)) GB
```

This is the most accurate way to calculate the total amount of the physical RAM. Unfortunately, it's probably also the slowest method because it needs to traverse all the memory block files on the file system. On my Ubuntu system, it could take up to 1 second (wall-clock time) to finish the calculation:

```
$ time ./calc-phy-ram.sh
68719476736 bytes
64 GB

real	0m1.025s
user	0m0.812s
sys	0m0.275s
```

### 3.3 Use `lsmem`

[This answer](https://stackoverflow.com/a/76641120/630364) uses `lsmem` to figure out the total amount of the physical RAM:

```shell
lsmem -b --summary=only | sed -ne '/online/s/.* //p'
```

In fact, using `lsmem` seems to be the same as using the online memory blocks. It can directly show the total online memory:

```
$ lsmem
RANGE                                 SIZE  STATE REMOVABLE  BLOCK
0x0000000000000000-0x000000007fffffff   2G online       yes   0-15
0x0000000100000000-0x000000107fffffff  62G online       yes 32-527

Memory block size:       128M
Total online memory:      64G
Total offline memory:      0B
```

Interestingly, `lsmem` can return the result almost instantly, whereas using the online memory blocks will take almost one second. `lsmem` is part of the package `util-linux` and the source code can be found in [`util-linux/util-linux`](https://github.com/util-linux/util-linux). `lsmem` is implemented by the source file `lsmem.c`. The function `void read_info(struct lsmem *lsmem)` seems to be the one that reads all the online memory blocks and adds up the sizes. The code from the version 2.39 (used on Ubuntu Noble) is quoted as follows (see [here](https://github.com/util-linux/util-linux/blob/stable/v2.39/sys-utils/lsmem.c#L455-L483)):

```c
static void read_info(struct lsmem *lsmem)
{
	struct memory_block blk;
	char buf[128];
	int i;

	if (ul_path_read_buffer(lsmem->sysmem, buf, sizeof(buf), "block_size_bytes") <= 0)
		err(EXIT_FAILURE, _("failed to read memory block size"));

	errno = 0;
	lsmem->block_size = strtoumax(buf, NULL, 16);
	if (errno)
		err(EXIT_FAILURE, _("failed to read memory block size"));

	for (i = 0; i < lsmem->ndirs; i++) {
		memory_block_read_attrs(lsmem, lsmem->dirs[i]->d_name, &blk);
		if (blk.state == MEMORY_STATE_ONLINE)
			lsmem->mem_online += lsmem->block_size;
		else
			lsmem->mem_offline += lsmem->block_size;
		if (is_mergeable(lsmem, &blk)) {
			lsmem->blocks[lsmem->nblocks - 1].count++;
			continue;
		}
		lsmem->nblocks++;
		lsmem->blocks = xrealloc(lsmem->blocks, lsmem->nblocks * sizeof(blk));
		*&lsmem->blocks[lsmem->nblocks - 1] = blk;
	}
}
```

It looks like the function `read_info()` doesn't do any magic but also simply loops through all the memory blocks and adds up their sizes. I haven't studied further, but I guess the shell script in the section 3.2 needs to start a lot of child processes to perform the file access and the starting/stopping of the child processes probably adds up a lot of overhead.

### 3.4 Use `DirectMapX` in `/proc/meminfo`

[This answer](https://stackoverflow.com/a/28286363) mentions the use of the `DirectMapX` entries in `/proc/meminfo`: Simply add the values up and convert the sum to the desired unit. On my machine, there are three `DirectMapX` entries:

```
DirectMap4k:      699496 kB
DirectMap2M:    26497024 kB
DirectMap1G:    39845888 kB
```

So the math is as follows:
* $699496 KiB + 26497024 KiB + 39845888 KiB = 67042408 KiB$
* $67042408 KiB \div (1024 KiB/MB) \div (1024 MiB/GiB) = 63.93662262 GiB \approx 64 GiB$

However, there is the question that whether all the memory has a direct map. In other words, the question is whether there can be a piece of memory that doesn't appear in any of the `DirectMap` entry. If there can be such memory, then the sum of all the `DirectMap` entries is not the total amount of physical memory on the machine. I need further study of how `DirectMapX` entries are created in order to answer this question. Therefore, **I would not choose this method to calculate the total amount of physical RAM.** (Besides, the user Goswin von Brederlow also complained [in this comment](https://stackoverflow.com/questions/20348007/how-can-i-find-out-the-total-physical-memory-ram-of-my-linux-box-suitable-to-b/28286363#comment91680096_28286363) that "this method doesn't seem to be reliable at all")
