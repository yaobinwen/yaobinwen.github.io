---
comments: true
date: 2022-06-22
layout: post
tags: [Tech,Linux,Ubuntu,GNOME]
title: How to customize the behaviors of the application launchers on Ubuntu Dock?
---

On Ubuntu (18.04+), the icons which you can click to launch the applications are called "launchers". In essence, these launchers are `.desktop` files that specify how the corresponding applications should be started, quite similar to the shortcuts on Windows.

On Ubuntu, after an application is installed, its launcher can be found in "Show Applications":

<img src="https://raw.githubusercontent.com/yaobinwen/yaobinwen.github.io/master/images/2022/06-22/Show-Applications.png" alt="Show Applications" height="50%" width="50%" />

The applications can also be added to the Dock (if enabled) which is the leftmost bar on the screenshot above. If you can find the `.desktop` files for the applications, you can also copy the `.desktop` files onto the Desktop to create the launchers there.

The technical specification of the `.desktop` files can be found in the article [1]. By changing the `.desktop` files, you can customize the behavior of the launchers, including the command line arguments and options (i.e., the `Exec` field).

The `.desktop` files of the launchers that you see in "Show Applications" and on the Dock can be found in two places:

- `/usr/share/applications`: Usually, an application will install its `.desktop` file in this system-wide path.
- `$HOME/.local/share/applications/`: The `.desktop` files in this path override the `.desktop` files in `/usr/share/applications`.

Therefore, if you want to customize the behavior of an application launcher, you can make a copy of its `.desktop` file in `$HOME/.local/share/applications` and modify this copy. For example, if you want to customize the launcher for Google Chrome, you can follow the steps below:

- Make sure you have the package `google-chrome-stable` installed.
- Find `google-chrome.desktop` in `/usr/share/applications`.
- Copy `/usr/share/applications/google-chrome.desktop` into `$HOME/.local/share/applications`.
- Modify the content of `$HOME/.local/share/applications/google-chrome.desktop`.

**However, you must be aware of two pitfalls that may make your customization effort ineffective.**

The first pitfall is: **The launcher in "Show Applications" and the launcher on the Dock may look the same but in fact they can be slightly different. Therefore, if you want to customize the `Exec` of the launcher, you must edit the correct `Exec` line.**

If you read [1], you'll find that a complete `.desktop` file may contain a few sections: one `[Desktop Entry]` section, possibly followed by one or more `[Desktop Action <action-name>]` sections. The `[Desktop Entry]` section defines the metadata about the launcher itself, including an `Exec` field that (I guess) defines the default command line to launch the application. Take Google Chrome for example, its `[Desktop Entry]` section (as found in `/usr/share/applications/google-chrome.desktop`) looks like this:

```
[Desktop Entry]
Version=1.0
Name=Google Chrome
# Only KDE 4 seems to use GenericName, so we reuse the KDE strings.
# From Ubuntu's language-pack-kde-XX-base packages, version 9.04-20090413.
GenericName=Web Browser
# Gnome and KDE 3 uses Comment.
Comment=Access the Internet
Exec=/usr/bin/google-chrome-stable %U
StartupNotify=true
Terminal=false
Icon=google-chrome
Type=Application
Categories=Network;WebBrowser;
MimeType=application/pdf;application/rdf+xml;application/rss+xml;application/xhtml+xml;application/xhtml_xml;application/xml;image/gif;image/jpeg;image/png;image/webp;text/html;text/xml;x-scheme-handler/http;x-scheme-handler/https;
Actions=new-window;new-private-window;
```

Because it has the field `Actions` (that has two actions), it will have two subsequent [`Desktop Action <action-name>]` sections for each action:

```
[Desktop Action new-window]
Name=New Window
Exec=/usr/bin/google-chrome-stable

[Desktop Action new-private-window]
Name=New Incognito Window
Exec=/usr/bin/google-chrome-stable --incognito
```

If you modify the `Exec` field in each section to do experiments, you will find that, in "Show Applications":

- If you click the Google Chrome icon directly, the `Exec` in **`[Desktop Entry]`** is run.
- If you click "New Window", the `Exec` in `[Desktop Action new-window]` is run.
- If you click "New Incognito Window", the `Exec` in `[Desktop Action new-private-window]` is run.

However, if you click the launcher on the Dock:

- If you click the Google Chrome icon directly, the `Exec` in **`[Desktop Action new-window]`** is run.
- If you click "New Window", the `Exec` in `[Desktop Action new-window]` is run.
- If you click "New Incognito Window", the `Exec` in `[Desktop Action new-private-window]` is run.

Google Chrome is an example to show that the launchers in "Show Applications" and on the Dock call different `Exec` fields in the `.desktop` file. However, if you use "Slack", the two launchers both call the `Exec` in `[Desktop Entry]`. This is because `slack.desktop` only has this section:

```
[Desktop Entry]
Name=Slack
StartupWMClass=Slack
Comment=Slack Desktop
GenericName=Slack Client for Linux
Exec=/usr/bin/slack %U
Icon=/usr/share/pixmaps/slack.png
Type=Application
StartupNotify=true
Categories=GNOME;GTK;Network;InstantMessaging;
MimeType=x-scheme-handler/slack;
```

So the point is: You need to study the `.desktop` file to figure out which `Exec` to change if you want to modify the launching command line. The rule-of-thumb is:
- If `.desktop` only has `[Desktop Entry]`, then both launchers use the `Exec` in this section.
- If `.desktop` has one or more `[Desktop Action <action-name>]` sections:
  - If the action `new-window` exists, the launcher on the Dock will use this action's `Exec` when it is clicked. But the launcher in "Show Applications" still uses the `Exec` in `[Desktop Entry]` when it is clicked.
  - If none of the actions are `new-window`, the launchers in "Show Applications" and on the Dock still use the `Exec` in `[Desktop Entry]`.

This can be verified if you look at the code. The Dock on Ubuntu 18.04 is implemented as a GNOME shell extension in [2]. The [source file `appIcons.js`](https://github.com/micheleg/dash-to-dock/blob/ubuntu-dock-0.9.1ubuntu18.04.1/appIcons.js) has the following code:

```javascript
                let appInfo = this._source.app.get_app_info();
                let actions = appInfo.list_actions();
                if (this._source.app.can_open_new_window() &&
                    actions.indexOf('new-window') == -1) {
                    this._newWindowMenuItem = this._appendMenuItem(_("New Window"));
                    this._newWindowMenuItem.connect('activate', Lang.bind(this, function() {
                        if (this._source.app.state == Shell.AppState.STOPPED)
                            this._source.animateLaunch();

                        this._source.app.open_new_window(-1);
                        this.emit('activate-window', null);
                    }));
                    this._appendSeparator();
                }
```

This piece of code says: If the launcher doesn't have the action `new-window`, the Dock will automatically add `New Window` as the default action.

The following piece of code implements the launching behavior:

```javascript
            if (actions.indexOf('new-window') == -1) {
                this.app.open_new_window(-1);
            }
            else {
                let i = actions.indexOf('new-window');
                if (i !== -1)
                    this.app.launch_action(actions[i], global.get_current_time(), -1);
            }
```

The second pitfall is: **The launchers in "Show Applications" and on the Dock seem to use some "cached" `.desktop` definition which is only refreshed when the `[Desktop Entry]` is changed. Therefore, if you only modify the section `[Desktop Action <action-name>]`, the launchers may still use the old `.desktop` definition.**

For example, if you modify the section `[Desktop Action new-window]` of Google Chrome to show "New Window 222" and launch a terminal when clicked:

```
[Desktop Action new-window]
Name=New Window 222
Exec=/usr/bin/gnome-terminal
```

After you save the `.desktop` file, you'll notice that the launchers are not updated at all: The action name is still "New Window" and clicking it still launches the Google Chrome browser window.

The key is you need to update something in the `[Desktop Entry]` section. Once you make a change there, you'll notice the launcher's icon is refreshed and then the action name becomes "New Window 222" and clicking it will launch a terminal window instead of the browser window.

References:
- [1] [_Unity Launchers And Desktop Files_](https://help.ubuntu.com/community/UnityLaunchersAndDesktopFiles)
- [2] [micheleg/dash-to-dock](https://github.com/micheleg/dash-to-dock)
