---
comments: true
date: 2022-06-23
layout: post
tags: [Tech,Linux,Ubuntu,GNOME]
title: How to read GNOME shell extension source code?
---

These days I tried to study the source code of the GNOME shell extension [micheleg/dash-to-dock](https://github.com/micheleg/dash-to-dock). However, I found the source code was not that easy to understand if you don't know **WHERE** to find the relevant source code.

Firstly, [the GNOME Wiki page for the shell extension](https://wiki.gnome.org/Projects/GnomeShell/Extensions) provides an overview for GNOME shell extensions. Specifically, read the [Creating Extensions](https://gjs.guide/extensions/development/creating.html#gnome-extensions-tool) page which tells you that the two essential files for an extension are `extension.js` and `metadata.json`. Therefore, when you start to read the source code of a GNOME shell extension, start with these two files.

In the source code, you will find a lot of `imports`. Take the [`appIcons.js` of `v0.9.1`](https://github.com/micheleg/dash-to-dock/blob/ubuntu-dock-0.9.1ubuntu18.04.1/appIcons.js) for example:

```javascript
const Clutter = imports.gi.Clutter;
const GdkPixbuf = imports.gi.GdkPixbuf
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Gtk = imports.gi.Gtk;
const Signals = imports.signals;
const Lang = imports.lang;
const Meta = imports.gi.Meta;
const Shell = imports.gi.Shell;
const St = imports.gi.St;
const Mainloop = imports.mainloop;
```

These `imports` fall into two major categories:
- Imported from `imports.gi`.
- Imported from `imports` directly.

The documentation for the first category can be found here: [gjs API references](https://gjs-docs.gnome.org/). Note that you must enable the document before you can open and read it. For example:

| Import | Documentation Link |
|-------:|:-------------------|
| imports.gi.Clutter | https://gjs-docs.gnome.org/clutter4~4_api/ |
| imports.gi.GdkPixbuf | https://gjs-docs.gnome.org/gdkpixbuf20~2.42.8/ |
| imports.gi.Gio | https://gjs-docs.gnome.org/gio20~2.66p/ |

The documentation for the second category can be found in the [source code of gjs](https://gitlab.gnome.org/GNOME/gjs). More specifically, in [modules/script](https://gitlab.gnome.org/GNOME/gjs/-/tree/master/modules/script), [modules/core](https://gitlab.gnome.org/GNOME/gjs/-/tree/master/modules/core), and [modules/core/overrides](https://gitlab.gnome.org/GNOME/gjs/-/tree/master/modules/core/overrides). For example,

| Import | Source Code Link |
|-------:|:-----------------|
| imports.signals | https://gitlab.gnome.org/GNOME/gjs/-/blob/master/modules/script/signals.js |
| imports.lang | https://gitlab.gnome.org/GNOME/gjs/-/blob/master/modules/script/lang.js |
| imports.mainloop | https://gitlab.gnome.org/GNOME/gjs/-/blob/master/modules/script/mainloop.js |
