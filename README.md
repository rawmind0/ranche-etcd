[![](https://images.microbadger.com/badges/image/rawmind/rancher-etcd.svg)](https://microbadger.com/images/rawmind/rancher-etcd "Get your own image badge on microbadger.com")

rancher-etcd
==============

This image is the etcd dynamic conf for rancher. It comes from [rancher-tools][rancher-tools].

## Build

```
docker build -t rawmind/rancher-etcd:<version> .
```

## Versions

- `2.3.7-5` [(Dockerfile)](https://github.com/rawmind0/rancher-etcd/blob/2.3.7-5/README.md)


## Usage

This image has to be run as a sidekick of [alpine-etcd][alpine-etcd], and makes available /opt/tools volume. It scans from rancher-metadata, for a etcd stack and service, and generates etcd connection string dynamicly.


[alpine-etcd]: https://github.com/rawmind0/alpine-etcd
[rancher-tools]: https://github.com/rawmind0/rancher-tools