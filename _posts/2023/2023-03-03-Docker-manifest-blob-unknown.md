---
comments: true
date: 2023-03-03
layout: post
tags: [Tech]
title: "An investigation of `docker manifest push` error: `manifest blob unknown: blob unknown to registry`"
---

## TL;DR

If you have an old manifest of the same name that was created from an earlier time, this old manifest may refer to some layers (i.e., blobs) that no longer exist now. The absence of these missing layers can also result in the `manifest blob unknown` error.

## The issue

Today I built a multi-platform Docker image for by building two separate Docker images for `amd64` and `arm64` and merging them with `docker manifest create ... --amend ...`. However, when I tried to push the manifest, I ran into the error `manifest blob unknown: blob unknown to registry`.

By the way, I'm aware of [`buildx`](https://docs.docker.com/build/building/multi-platform/). I used `docker manifest` because it was used in my work.

By searching the error message, I found two related links that talked about one possible cause. See [1] and [2].

[1] explains what caused the error, as I quoted below:

> In the version that's not working, you tag each individual manifest with `$CI_REGISTRY_IMAGE/$ARCH:$CI_COMMIT_SHORT_SHA` and the manifest list with `$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA`.
>
> Although you have access to both parent (`$CI_REGISTRY_IMAGE`) and child (`$CI_REGISTRY_IMAGE/$ARCH`) repositories, when you push the manifest list to the parent, the registry will try to find all blobs referenced in the individual manifests within that repository. Because the individual manifests were pushed to the child repository, their blobs won't be in the parent repository, and thus the manifest blob unknown: blob unknown to registry error when you try to push the manifest list.
The other example is OK because you're using the same repository for both individual manifests and the manifest list (`$CI_REGISTRY_IMAGE`).

However, this didn't apply to me. In their situation, the error was likely caused by "having multiple images with different architectures, spread out over several repositories instead of the same repository." For example, [2] mentioned the case in which the question owner had two images:
- `registry.gitlab.com/paleozogt/dockerfun/amd64:6b972be0`
- `registry.gitlab.com/paleozogt/dockerfun/arm64:6b972be0`

He/she tried to put them into a multi-platform image called `registry.gitlab.com/paleozogt/dockerfun:6b972be0` but couldn't, because the `amd64` image was in the repository `registry.gitlab.com/paleozogt/dockerfun/amd64` while the `arm64` image was in the repository `registry.gitlab.com/paleozogt/dockerfun/arm64`. As a result, the question owner ran into the `blob unknown to registry` error.

In my case, I followed the advice that [1] gives: The two platform-specific images were as follows:

- `yb.m.io/sandbox:0.16-edge-amd64`
- `yb.m.io/sandbox:0.16-edge-arm64`

They were in the same repository `yb.m.io/sandbox`. I could create the manifest for the multi-platform image:

```
$ docker manifest create yb.m.io/sandbox:0.16-edge \
    --amend yb.m.io/sandbox:0.16-edge-amd64 \
    --amend yb.m.io/sandbox:0.16-edge-arm64
```

But when I tried to push the manifest, I still ran into the error:

```
$ docker manifest push yb.m.io/sandbox:0.16-edge
```

So it must be because of something else.

## Investigation

The error message `manifest blob unknown: blob unknown to registry` actually gave me a hint: **Some blob that the manifest refers to does not exist on the Docker Registry**. So I would need to do two things:

- 1). Figure out what blobs the concerned manifest refers to.
- 2). Figure out what blobs are known to the Registry so I can determine whether some manifest blobs are missing there.

To find the blobs that the multi-platform image manifest refers to, I ran `docker manifest inspect` to list of the layers (i.e., blobs) as follows. For simplicity, I only listed one of the layers:

```json
$ docker manifest inspect --verbose yb.m.io/sandbox:0.16-edge

[
  {
    "Ref": "yb.m.io/sandbox:0.16-edge-amd64",
    "Descriptor": {
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "digest": "sha256:0e32bf6bcd30c37d19b4527d162d39a50c77cc4fd6d063e43d235f73acd39069",
      "size": 1777,
      "platform": {
        "architecture": "amd64",
        "os": "linux"
      }
    },
    "SchemaV2Manifest": {
      "schemaVersion": 2,
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "config": {
        "mediaType": "application/vnd.docker.container.image.v1+json",
        "size": 3551,
        "digest": "sha256:3752770f4df01e0ea97372a0163b321ff5f40dbee350a4d3f26a95c12c5d1870"
      },
      "layers": [
        ...
        {
          "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
          "size": 2107098,
          "digest": "sha256:5d20c808ce198565ff70b3ed23a991dd49afac45dece63474b27ce6ed036adc6"
        },
        ...
      ]
    }
  }
  ...
]
```

There are two ways to find the blobs that are known to the Registry. The first way is to query each blob using [Docker Registry's Blob HTTP API](https://docs.docker.com/registry/spec/api/#blob):

```
$ curl --head https://yb.m.io/v2/sandbox/blobs/sha256:5d20c808ce198565ff70b3ed23a991dd49afac45dece63474b27ce6ed036adc6
```

The argument `--head` prevents `curl` from fetching the actual content of the blob while still returning the HTTP status code that indicates the existence of the blob. If it returns `404 Not Found`, the blob doesn't exist on the Registry; if it returns `200 OK`, the blob exists.

By the way, you may need to authenticate yourself when you run the `curl` command above.

The second way is to examine the Registry's underlying storage folder if you have the access to the Registry server. For example, I am also the administrator of the Registry I was using, so I could log in the Registry server, find the Registry's underlying storage folder, and run `tree` to list the blobs:

```
.
└── sha256
    ├── 00
    │   └── 0064b1b97ec0775813740e8cb92821a6d84fd38eee70bafba9c12d9c37534661
    ├── 02
    │   └── 025c7e61478d595b901c7e884d4c92e5c13c75613f22328c284044b253260bca
    ...
    ...
    └── db
        └── dbfefb1a4953c4f7a8a8a994c8ae0da48cbec04c8c3666fe8c07743f88c9a1ff
```

By comparing the blobs that `docker manifest inspect` listed and the blobs that were known to the Registry, I found that the manifest did refer to a few blobs that didn't exist on the Registry.

## Why were there missing blobs?

Why were there missing blobs? [1] and [2] mention the case that the platform-specific images are not in the same repository of the multi-platform image. But my case is different from theirs. After recalling what I did, I realized the missing blobs in my case was caused by the multi-platform manifest was not re-created after I rebuilt my platform-specific images.

Here is the timeline of what I did:

- T1 (i.e., time point 1): I built `yb.m.io/sandbox:0.16-edge-amd64`.
- T2: I built `yb.m.io/sandbox:0.16-edge-arm64`.
- T3: I created the manifest for the multi-platform image `yb.m.io/sandbox:0.16-edge`.
- T4: I removed the platform-specific images because I built the images using the wrong input files.
- T5: I re-built `yb.m.io/sandbox:0.16-edge-amd64` and ``yb.m.io/sandbox:0.16-edge-arm64` using the correct input files.
- T6: I re-created the manifest for the multi-platform image.

The first problem happened in T6. When I re-created the multi-platform image manifest, the command told me it was "created":

```
$ docker manifest create yb.m.io/sandbox:0.16-edge \
    --amend yb.m.io/sandbox:0.16-edge-amd64 \
    --amend yb.m.io/sandbox:0.16-edge-arm64
$ Created manifest list yb.m.io/sandbox:0.16-edge
```

However, it didn't. What probably happened was `docker manifest create` detected the existing manifest that I created at T3 so the command didn't create a new manifest to overwrite the existing one. Nonetheless, it still reported the status as "Created manifest list".

You can follow the steps below to reproduce the problem. Note that you need a remote Registry because the manifest is "a reference to images in the registry, and reference the image's digest" and this digest "is calculated when the image is pushed." As a result, you can't perform the following steps only on your local machine. One option is to do the experiment with your own Docker Hub account.

The reproduce steps are:

- 1). Create `/tmp/manifest/Dockerfile` with the following content:

```dockerfile
FROM alpine:3.14
RUN echo "hello" > /tmp/data.txt
```

- 2). Under `/tmp/manifest`, run `docker build -t yb.m.io/sandbox:0.16-amd64 .`.
- 3). Run `docker image ls yb.m.io/sandbox:0.16-amd64` to verify the creation of the image:

```
REPOSITORY   TAG          IMAGE ID       CREATED              SIZE
sandbox         0.16-amd64   a94f0470b830   About a minute ago   5.61MB
```

- 4). Run `docker push yb.m.io/sandbox:0.16-amd64` to push the image to the remote Registry so the manifest is created as well.
- 5). Run `docker manifest inspect --verbose yb.m.io/sandbox:0.16-amd64` to view the manifest:

```json
{
  "Ref": "yb.m.io/sandbox:0.16-amd64",
  "Descriptor": {
    "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
    "digest": "sha256:84f5b72ed31e7e832e341820325d5fe0365dcd5c1d75a2408798e9b239745ff2",
    "size": 735,
    "platform": {
      "architecture": "amd64",
      "os": "linux"
    }
  },
  "SchemaV2Manifest": {
    "schemaVersion": 2,
    "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
    "config": {
      "mediaType": "application/vnd.docker.container.image.v1+json",
      "size": 1117,
      "digest": "sha256:a94f0470b830e1ee0783fbaa17be5b2b92825e0ab209f0dd27b859ff3b31e197"
    },
    "layers": [
      {
        "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
        "size": 2829633,
        "digest": "sha256:d261077062b2aebb9ca8dc61f2b00e7e2b4e44179d3cfbe526c4ee0c5e41b26f"
      },
      {
        "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
        "size": 155,
        "digest": "sha256:811d34c4ff8c5909f1a76ff51a468e0bcbe7215121403f8a196f2f1cc19fce67"
      }
    ]
  }
}
```

- 6). Run `docker manifest create yb.m.io/sandbox:0.16 --amend yb.m.io/sandbox:0.16-amd64` to create the manifest for the multi-platform image.
- 7). Run `docker manifest inspect --verbose yaobinwen/sandbox:0.16` to examine the manifest of the multi-platform image. You'll see that it refers to `yb.m.io/sandbox:0.16-amd64` that we saw in step 5 (i.e., the `Descriptor` section in this step is the same as that in step 5):

```json
[
  {
    "Ref": "yb.m.io/sandbox:0.16-amd64",
    "Descriptor": {
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "digest": "sha256:84f5b72ed31e7e832e341820325d5fe0365dcd5c1d75a2408798e9b239745ff2",
      "size": 735,
      "platform": {
        "architecture": "amd64",
        "os": "linux"
      }
    },
    ...
]
```

- 8). Run `docker image rm yb.m.io/sandbox:0.16-amd64` to only remove the image. Note we are not removing the manifest of the multi-platform image and this buries the root of the issue.
- 9). Delete the repository on the Registry and re-create a new one of the same name. In real use, there can be other things that cause the blobs on the remote Registry to be deleted but deleting and re-creating the repository is the fastest method to achieve this (especially when you are using Docker Hub to reproduce this issue).
- 10). Change `Dockerfile` to the following content:

```dockerfile
FROM alpine:3.14
RUN echo "world" > /tmp/data.txt
```

- 11). Run step 2 again to create a new image of the same tag. But this `yb.m.io/sandbox:0.16-amd64` has different content than the one we created in step 2.
- 12). Run step 4 to push the newly created image to the Registry.
- 13). Run step 5 to view the new manifest content. Note that most of the digests in this step are different from the digests in step 5. The only one that remains the same is the first layer of digest `sha256:d261077062b2aebb9ca8dc61f2b00e7e2b4e44179d3cfbe526c4ee0c5e41b26f` which points to the base image `alpine:3.14`.

```json
{
  "Ref": "yb.m.io/sandbox:0.16-amd64",
  "Descriptor": {
    "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
    "digest": "sha256:73cd8eec8c72a0e5276e69242a7f2754f538fcb5591b089e4ab914059b7bf3c0",
    "size": 735,
    "platform": {
      "architecture": "amd64",
      "os": "linux"
    }
  },
  "SchemaV2Manifest": {
    "schemaVersion": 2,
    "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
    "config": {
      "mediaType": "application/vnd.docker.container.image.v1+json",
      "size": 1117,
      "digest": "sha256:cc43047d373d9881937f6a7cc9be73390598107f16b22457f17536909d5f2758"
    },
    "layers": [
      {
        "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
        "size": 2829633,
        "digest": "sha256:d261077062b2aebb9ca8dc61f2b00e7e2b4e44179d3cfbe526c4ee0c5e41b26f"
      },
      {
        "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
        "size": 151,
        "digest": "sha256:f09126c312eb7c724c04256f9aaf4cff2a92a76d862a8c93401f8e2c41b5a5db"
      }
    ]
  }
}
```

- 14). Run step 6 to "re-create" the manifest for the multi-platform image. Note the command output would say "Created manifest list" that makes you think a new, updated manifest was created using the latest manifest of `yb.m.io/sandbox:0.16-amd64`.
- 15). Run step 7 to examine the manifest of the multi-platform image again. Surprisingly (or not at all), you'll see its content is the same as step 7, so it still refers to the Docker image that we created in step 5, not the image we created in step 10.

```json
[
  {
    "Ref": "yb.m.io/sandbox:0.16-amd64",
    "Descriptor": {
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "digest": "sha256:84f5b72ed31e7e832e341820325d5fe0365dcd5c1d75a2408798e9b239745ff2",
      "size": 735,
      "platform": {
        "architecture": "amd64",
        "os": "linux"
      }
    },
    "SchemaV2Manifest": {
      "schemaVersion": 2,
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "config": {
        "mediaType": "application/vnd.docker.container.image.v1+json",
        "size": 1117,
        "digest": "sha256:a94f0470b830e1ee0783fbaa17be5b2b92825e0ab209f0dd27b859ff3b31e197"
      },
      "layers": [
        {
          "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
          "size": 2829633,
          "digest": "sha256:d261077062b2aebb9ca8dc61f2b00e7e2b4e44179d3cfbe526c4ee0c5e41b26f"
        },
        {
          "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
          "size": 155,
          "digest": "sha256:811d34c4ff8c5909f1a76ff51a468e0bcbe7215121403f8a196f2f1cc19fce67"
        }
      ]
    }
  }
]
```

- 16). Run `docker manifest push yb.m.io/sandbox:0.16` and you will run into the error `manifest blob unknown: blob unknown to registry`.

## Fix

To fix the error, you can remove the multi-platform image manifest, re-create it, and push it.

## References

- [1] [Issue: pushing manifest to registry gets error "manifest blob unknown"](https://gitlab.com/gitlab-org/gitlab/-/issues/209008#note_425575855)
- [2] [Merge Request: Explaining solution multi-arch blob-unknown error](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/79413/diffs)
- [3] [docker/cli: allow to create manifests of local images](https://github.com/docker/cli/issues/3350#issuecomment-957344873)
