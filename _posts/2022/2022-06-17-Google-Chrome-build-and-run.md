---
comments: true
date: 2022-06-17
layout: post
tags: [Tech]
title: "Google Chromium: Check out, build, and hack the code"
---

## 1. The revision of the code

I needed to study Google Chromium by hacking the code, so I decided to build the code by myself. This article records the notes of building and hacking the code on Ubuntu 18.04.

The primary article to refer to is [_Checking out and building Chromium on Linux_](https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md). The instructions in this article are already very clear, but one possible pitfall is: The command `gclient runhooks` probably checks out the dependent 3rd-party libraries that are required to build Chromium. However, the default revisions of these libraries may only work for the latest code (i.e., the `main` branch) of Chromium. If you want to use a historical revision of Chromium, you may have to roll the 3rd-party libraries back to appropriate revisions, too. Otherwise, the step `gn gen out/Default` may report errors about 3rd-party libraries.

## 2. Install the build dependencies

On Ubuntu 18.04 (and possibly higher), when you run `./build/install-build-deps.sh` to install the build dependencies, you may (or may not) run into the APT errors about installing `libgl1:i386` and `libegl1:i386`. This seems to be because `install-build-deps.sh` doesn't correctly detect the package name for `libgl1` and `libegl1` on Ubuntu 18.04. The problematic part of the code is this:

```shell
# this can be moved into the lib list without a guard when xenial is deprecated
if package_exists libgl1; then
  lib_list="${lib_list} libgl1"
fi
if package_exists libegl1; then
  lib_list="${lib_list} libegl1"
fi
if package_exists libgl1:i386; then
  lib_list="${lib_list} libgl1:i386"
fi
if package_exists libegl1:i386; then
  lib_list="${lib_list} libegl1:i386"
fi
```

You can apply the following patch to fix the issue:

```diff
From e9b811c7a7735a162cf5bb2669736391e37adc8e Mon Sep 17 00:00:00 2001
From: Yaobin Wen <robin.wyb@gmail.com>
Date: Wed, 29 Jun 2022 18:19:28 -0400
Subject: [PATCH] Fix install-build-deps.sh

---
 build/install-build-deps.sh | 18 +++---------------
 1 file changed, 3 insertions(+), 15 deletions(-)

diff --git a/build/install-build-deps.sh b/build/install-build-deps.sh
index 2c305f5eb7eef..f0ba04d363e0e 100755
--- a/build/install-build-deps.sh
+++ b/build/install-build-deps.sh
@@ -99,7 +99,7 @@ fi
 distro_codename=$(lsb_release --codename --short)
 distro_id=$(lsb_release --id --short)
 # TODO(crbug.com/1199405): Remove 14.04 (trusty) and 16.04 (xenial).
-supported_codenames="(trusty|xenial|bionic|disco|eoan|focal|groovy)"
+supported_codenames="(bionic|disco|eoan|focal|groovy)"
 supported_ids="(Debian)"
 if [ 0 -eq "${do_unsupported-0}" ] && [ 0 -eq "${do_quick_check-0}" ] ; then
   if [[ ! $distro_codename =~ $supported_codenames &&
@@ -237,11 +237,13 @@ common_lib_list="\
   libcap2
   libcups2
   libdrm2
+  libegl1
   libevdev2
   libexpat1
   libfontconfig1
   libfreetype6
   libgbm1
+  libgl1
   libglib2.0-0
   libgtk-3-0
   libpam0g
@@ -284,20 +286,6 @@ lib_list="\
   $chromeos_lib_list
 "

-# this can be moved into the lib list without a guard when xenial is deprecated
-if package_exists libgl1; then
-  lib_list="${lib_list} libgl1"
-fi
-if package_exists libegl1; then
-  lib_list="${lib_list} libegl1"
-fi
-if package_exists libgl1:i386; then
-  lib_list="${lib_list} libgl1:i386"
-fi
-if package_exists libegl1:i386; then
-  lib_list="${lib_list} libegl1:i386"
-fi
-
 # 32-bit libraries needed e.g. to compile V8 snapshot for Android or armhf
 lib32_list="linux-libc-dev:i386 libpci3:i386"

--
2.36.1
```

## 3. Build the code

In order to run Chromium, you must have a sandbox, too. However, the default step `autoninja -C out/Default chrome` doesn't build the sandbox. If you run the built `out/Default/chrome` without a sandbox, you will see the following error message:

> [22827:22827:0629/175258.631346:FATAL:zygote_host_impl_linux.cc(117)] No usable sandbox! Update your kernel or see https://chromium.googlesource.com/chromium/src/+/main/docs/linux/suid_sandbox_development.md for more information on developing with the SUID sandbox. If you want to live dangerously and need an immediate workaround, you can try using --no-sandbox.

You can still run the built Chrome with `--no-sandbox`, but that is not recommended.

After reading the document [_Linux SUID Sandbox Development_](https://chromium.googlesource.com/chromium/src/+/main/docs/linux/suid_sandbox_development.md), I figured out the steps to build the sandbox and run Chrome with it are as follows:

- Run `autoninja -C out/Default chrome chrome_sandbox` to build both Chrome and the sandbox. The Chrome sandbox path is `out/Default/chrome_sandbox`.
- Change its ownership to `root:root`: `sudo chown root:root out/Default/chrome_sandbox`.
- Change its mode to `4755`: `sudo chmod 4755 out/Default/chrome_sandbox`
- Export the environment variable `CHROME_DEVEL_SANDBOX` to include the sandbox's path: `export CHROME_DEVEL_SANDBOX="$PWD/chrome_sandbox"`

`chrome_sandbox` must have the mode `4755` and be owned by `root:root`, otherwise an error message will be reported:

> [5568:5568:0629/180155.140544:FATAL:setuid_sandbox_host.cc(157)] The SUID sandbox helper binary was found, but is not configured correctly. Rather than run without sandboxing I'm aborting now. You need to make sure that /home/ywen/yaobin/googlesource/chromium-full/src/out/Default/chrome_sandbox is owned by root and has mode 4755.

## 4. Hack the code

Every time you modify the code, just run `autoninja -C out/Default chrome chrome_sandbox`. `autoninja` will smartly figure out the changed files and only build the changed artifacts. However, because Chromium is a huge project, it may still take quite a lot of time to build the changed files.

The `main` entry point on Linux is in `chrome/app/chrome_exe_main_aura.cc`:

```cpp
int main(int argc, const char** argv) {
  return ChromeMain(argc, argv);
}
```

The `ChromeMain` function is defined in `chrome/app/chrome_main.cc`:

```cpp
#elif BUILDFLAG(IS_POSIX) || BUILDFLAG(IS_FUCHSIA)
extern "C" {
// This function must be marked with NO_STACK_PROTECTOR or it may crash on
// return, see the --change-stack-guard-on-fork command line flag.
__attribute__((visibility("default"))) int NO_STACK_PROTECTOR
ChromeMain(int argc, const char** argv);
}
```

However, it's still possible that you can't find the call chain of a function. In this case, you can create a "division by zero" exception to cause the call stack to be printed:

```cpp
int a = 0;
printf("[ywen] Print call stack: %d\n", 1/a);
```

Then a core dump will be created due to "Floating point exception (core dumped)" in `/var/crash` and you can use `gdb` to load the core to examine the call stack:

```
(gdb) bt
#0  0x000055aec90cfbac in ChromeMain(int, char const**) (argc=1, argv=0x7ffc20b3bd58) at ../../chrome/app/chrome_main.cc:109
#1  0x000055aec90cfb60 in main(int, char const**) (argc=1, argv=0x7ffc20b3bd58) at ../../chrome/app/chrome_exe_main_aura.cc:19
(gdb)
```

Note that you can't directly write `1/0` in the code because the compiler can detect the division by zero error and refuse to compile the code:

```
../../chrome/app/chrome_main.cc:109:13: error: division by zero is undefined [-Werror,-Wdivision-by-zero]
  int a = 1 / 0;
            ^ ~
```

But sometimes the call stack will be printed directly. For example, if you add the division by zero error into the method `RenderWidgetHostViewAura::RenderWidgetHostViewAura(...)` in `content/browser/renderer_host/render_widget_host_view_aura.cc`, when you run the code, the call stack will be printed:

```
Received signal 8 FPE_INTDIV 7f57502f9334
#0 0x7f57577fa8ef base::debug::CollectStackTrace()
#1 0x7f575755c8ea base::debug::StackTrace::StackTrace()
#2 0x7f575755c8a5 base::debug::StackTrace::StackTrace()
#3 0x7f57577fa3bc base::debug::(anonymous namespace)::StackDumpSignalHandler()
#4 0x7f5716cf5980 (/lib/x86_64-linux-gnu/libpthread-2.27.so+0x1297f)
#5 0x7f57502f9334 content::RenderWidgetHostViewAura::RenderWidgetHostViewAura()
#6 0x7f57506fc4a9 content::WebContentsViewAura::CreateViewForWidget()
#7 0x7f57506a4ff0 content::WebContentsImpl::CreateRenderWidgetHostViewForRenderManager()
#8 0x7f57506a529b content::WebContentsImpl::CreateRenderViewForRenderManager()
#9 0x7f5750206cc0 content::RenderFrameHostManager::InitRenderView()
#10 0x7f5750200ef1 content::RenderFrameHostManager::ReinitializeMainRenderFrame()
#11 0x7f57501ff9ef content::RenderFrameHostManager::GetFrameHostForNavigation()
#12 0x7f57501fe724 content::RenderFrameHostManager::DidCreateNavigationRequest()
#13 0x7f574feffce6 content::FrameTreeNode::CreatedNavigationRequest()
#14 0x7f575010e8f0 content::Navigator::Navigate()
#15 0x7f575008a372 content::NavigationControllerImpl::NavigateWithoutEntry()
#16 0x7f57500898bb content::NavigationControllerImpl::LoadURLWithParams()
#17 0x55dafc79c446 (anonymous namespace)::LoadURLInContents()
#18 0x55dafc79a3c0 Navigate()
#19 0x55dafc84a422 StartupBrowserCreatorImpl::OpenTabsInBrowser()
#20 0x55dafc84b32d StartupBrowserCreatorImpl::RestoreOrCreateBrowser()
#21 0x55dafc849cd0 StartupBrowserCreatorImpl::DetermineURLsAndLaunch()
#22 0x55dafc84940c StartupBrowserCreatorImpl::Launch()
#23 0x55dafc841d3f StartupBrowserCreator::LaunchBrowser()
#24 0x55dafc842b14 StartupBrowserCreator::ProcessLastOpenedProfiles()
#25 0x55dafc8424f2 StartupBrowserCreator::LaunchBrowserForLastProfiles()
#26 0x55dafc8419fc StartupBrowserCreator::ProcessCmdLineImpl()
#27 0x55dafc84071d StartupBrowserCreator::Start()
#28 0x55daf86de0de ChromeBrowserMainParts::PreMainMessageLoopRunImpl()
#29 0x55daf86dd152 ChromeBrowserMainParts::PreMainMessageLoopRun()
#30 0x7f574f3a6588 content::BrowserMainLoop::PreMainMessageLoopRun()
#31 0x7f574f3b089a base::internal::FunctorTraits<>::Invoke<>()
#32 0x7f574f3b07d4 base::internal::InvokeHelper<>::MakeItSo<>()
#33 0x7f574f3b079a _ZN4base8internal7InvokerINS0_9BindStateIMN7content15BrowserMainLoopEFivEJNS0_17UnretainedWrapperIS4_EEEEEFivEE7RunImplIS6_NSt2Cr5tupleIJS8_EEEJLm0EEEEiOT_OT0_NSD_16integer_sequenceImJXspT1_EEEE
#34 0x7f574f3b06d7 base::internal::Invoker<>::RunOnce()
#35 0x7f57505c2cd9 _ZNO4base12OnceCallbackIFivEE3RunEv
#36 0x7f57505c298e content::StartupTaskRunner::RunAllTasksNow()
#37 0x7f574f3a604b content::BrowserMainLoop::CreateStartupTasks()
#38 0x7f574f3b3176 content::BrowserMainRunnerImpl::Initialize()
#39 0x7f574f3a37e8 content::BrowserMain()
#40 0x7f575194a6c9 content::RunBrowserProcessMain()
#41 0x7f575194c2ff content::ContentMainRunnerImpl::RunBrowser()
#42 0x7f575194bb4c content::ContentMainRunnerImpl::Run()
#43 0x7f57519483bd content::RunContentProcess()
#44 0x7f5751948d22 content::ContentMain()
#45 0x55daf46a7d46 ChromeMain
#46 0x55daf46a7b60 main
#47 0x7f5715503c87 __libc_start_main
#48 0x55daf46a7a6a _start
  r8: 00007ffc52fe0188  r9: 00007f56f80ded60 r10: 000055daffc5b010 r11: 0000000000000000
 r12: 000055daf46a7a40 r13: 00007ffc52fe4fd0 r14: 00007ffc52fe1ba0 r15: 0000000000000000
  di: 00007ffc52fe03c0  si: 00007ffc52fe03c0  bp: 00007ffc52fe0910  bx: 0000000000000000
  dx: 0000000000000000  ax: 0000000000000001  cx: 000055daffd69700  sp: 00007ffc52fe0550
  ip: 00007f57502f9334 efl: 0000000000010202 cgf: 002b000000000033 erf: 0000000000000000
 trp: 0000000000000000 msk: 0000000000000000 cr2: 0000000000000000
[end of stack trace]
Floating point exception (core dumped)
```

The call stack can help you figure out how a function is called.
