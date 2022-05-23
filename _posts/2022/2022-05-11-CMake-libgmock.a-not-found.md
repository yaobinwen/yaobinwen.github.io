---
comments: true
date: 2022-05-11
layout: post
tags: [Tech,CMake,GoogleTest]
title: "Why does CMake report the missing of `libgmock.a`?"
---

A few weeks ago, I ran into the following CMake error when building our code:

```
CMake Error at /usr/lib/x86_64-linux-gnu/cmake/GTest/GTestTargets.cmake:110 (message):
  The imported target "GTest::gmock" references the file

     "/usr/lib/x86_64-linux-gnu/libgmock.a"

  but this file does not exist.  Possible reasons include:

  * The file was deleted, renamed, or moved to another location.

  * An install or uninstall procedure did not complete successfully.

  * The installation package was faulty and contained

     "/usr/lib/x86_64-linux-gnu/cmake/GTest/GTestTargets.cmake"

  but not all the files it references.

Call Stack (most recent call first):
  /usr/lib/x86_64-linux-gnu/cmake/GTest/GTestConfig.cmake:42 (include)
  /usr/share/cmake-3.22/Modules/FindGTest.cmake:187 (find_package)
  /opt/ros/melodic/share/catkin/cmake/test/gtest.cmake:340 (find_package)
  /opt/ros/melodic/share/catkin/cmake/all.cmake:164 (include)
  /opt/ros/melodic/share/catkin/cmake/catkinConfig.cmake:20 (include)
  CMakeLists.txt:58 (find_package)

-- Configuring incomplete, errors occurred!
```

However, we didn't encounter this error when we were using CMake 3.15. This error happened when we switched to CMake 3.21+.

After some investigation, I figured out the general reason why the error didn't happen on 3.15 but on a newer version:
- 1). `cmake 3.15` and `cmake 3.21` look for `gtest` differently. In other words, the files `usr/share/cmake-<version>/Modules/FindGTest.cmake` of the two versions are different.
- 2). To be honest, I haven't figured out how exactly they look for the `gtest` modules, but:
  - a). For `cmake 3.15`, it looks like `FindGTest.cmake` only looks for `gtest`-related files and doesn't look for `gmock`-related files. Therefore, `cmake 3.15` doesn't report the missing of `libgmock.a`. (However, if the package `cmake-extras` is installed, `cmake-extras` provides `GMockConfig.cmake` that adds an external CMake project that builds `gtest` and `gmock` from the source.)
  - b). For `cmake 3.21`, it looks like `FindGTest.cmake` looks for both `gtest`- and `gmock`-related files. This is why the error above about missing `libgmock.a` was reported. There are two methods to resolve this issue:
    - i). Install `cmake-extras` so `GMockConfig.cmake` will add an external CMake project to build `gtest` and `gmock` from the source. See the log messages below.
    - ii). Install `libgmock-dev` to install `libgmock.a` to the system.

However, as I read more about GoogleTest's CMake code, it gave me the feeling that **the way GoogleTest should be used depends on whether the code is built with only `gtest` enabled, or with `gtest` and `gmock` both enabled.**

According to [GoogleTest's CMake file, line 25](https://github.com/google/googletest/blob/release-1.11.0/CMakeLists.txt#L25):

```cmake
option(BUILD_GMOCK "Builds the googlemock subproject" ON)
```

by default, both `gtest` and `gmock` are enabled (because building `gmock` implies building `gtest`). Therefore, after the code is built, the generated `googletest/CMakeFiles/Export/lib/cmake/GTest/GTestTargets.cmake` has all the CMake `Target` instances:
- `gtest`
- `gtest_main`
- `gmock`
- `gmock_main`

In contrast, when I disabled the build of `gmock`, the generated `GTestTargets.cmake` only contains the `Target` instances of `gtest` and `gtest_main`. That all these `Target` instances are contained in the same `GTestTargets.cmake` **seems to suggest that the package `GoogleTest` also expects that the users need to install both `gtest` and `gmock` on the system.**

However, the package `gtest` only installs `gtest`-related `Target` instances (`gtest`, `gtest_main`); the package `gmock`, however, installs both `gtest`- and `gmock`-related `Target` instances. Therefore, if one consuming package depends on `gtest` only, it should install the `gtest` Debian packages that were built **with `gmock` disabled** so the `GTestTargets.cmake` wouldn't contain anything about `gmock`. If the consuming package depends on `gmock`, it will need to install `gmock` Debian package. Because `gmock` always includes `gtest`, so all the four `Target` instances mentioned above will be installed, too, and that wouldn't cause any error.

In my case, my project builds `GoogleTest` by ourselves and we are using the default build options, which means we build `GoogleTest` with both `gtest` and `gmock` enabled. Therefore, the generated `GTestTargets.cmake` will need all the four `Target` instances be present on the system. However, because the code that I built above only depends on `gtest`, the Debian build tools only install `gtest` Debian packages, so the `gmock` part is missing, hence the `gmock`-related build errors.

I feel the root cause of the issue is somewhere in `GoogleTest`: I think they should have split `GTestTargets.cmake` into two parts, one for `gtest` and one for `gmock`, so no matter if the source code is built with one or both enabled, the users can always install and use only the part(s) they really need, and not "tethered" to all of them if the package was built with both `gtest` and `gmock` enabled. 
