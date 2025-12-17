# Docker Images for Fink

This repository contains the unified Docker build system for Fink. It centralizes all image builds for both local development and Kubernetes deployment.

## Architecture

This repository provides:
- **Dockerfile.k8s**: Unified Kubernetes images (replaces fink-broker/Dockerfile)
- **rubin/Dockerfile**: Local development images for Rubin survey
- **ztf/Dockerfile**: Local development images for ZTF survey
- **build-images.sh**: Unified build script
- **common/deps/**: Shared dependencies (JAR URLs)
- Survey-specific dependencies in `rubin/deps/` and `ztf/deps/`

## Workflow

We mainly use these in the Continuous Integration of various repositories. The image is built at each release of this repository: 

```
# push modifications
git tag <number>
git push origin --tags

# then publish release on GH
```

The code is currently checked on `Almalinux:9`. 

| | Latest |
|-|-----|
| OS | AlmaLinux 9 |
| Spark | 3.4.1 |
| Hadoop | 3.2 |
| Java |11 |
| HBase | 2.4.10 |
| Kafka | 2.8.1 |

The production environment is currently in use at VirtualData, Université Paris-Saclay, to process the ZTF alert stream. For development purposes, one can build locally images using the unified build script:

```bash
./build-images.sh -h
Usage: build-images.sh [options]

  Available options:
    -h                  this message
    -t TARGET           target to build: k8s, rubin, ztf
    -s SUFFIX           image suffix for k8s builds: noscience, science (default: science)
    -i SURVEY           survey for k8s builds: ztf, rubin (default: ztf)
    --tag TAG          docker tag name (required for rubin/ztf builds)
    --verbose           verbose build output
    --run              run the container after build (for rubin/ztf)

Build Fink Docker images:
  - k8s: Build Kubernetes image using Dockerfile.k8s
  - rubin: Build local development image for Rubin survey
  - ztf: Build local development image for ZTF survey

Examples:
  build-images.sh -t k8s -s noscience -i ztf     # K8s noscience image for ZTF
  build-images.sh -t k8s -s science -i rubin     # K8s science image for Rubin
  build-images.sh -t rubin --tag myrubin:latest  # Local Rubin image
  build-images.sh -t ztf --tag myztf:latest      # Local ZTF image
```

This unified script replaces the previous separate build processes and supports both local development images (rubin/ztf) and Kubernetes deployment images.

### Building an image

To build images, use the unified build script:

```bash
# Build local development image for ZTF survey
./build-images.sh -t ztf --tag dev

# Build local development image for Rubin survey
./build-images.sh -t rubin --tag rubin-dev

# Build Kubernetes science image for ZTF
./build-images.sh -t k8s -s science -i ztf

# Build Kubernetes noscience image for Rubin
./build-images.sh -t k8s -s noscience -i rubin
```

You might need to modify resolvers though. In this case, just add in `/etc/resolv.conf`

```
nameserver 8.8.8.8
```

and restart docker before building your image.

Without optimisation, the images are quite big because of dependencies. Here is the breakdown for an image based on centos7 with a single build stage (size on disk):

|        | size |
|--------|------|
| centos7| 204MB|
| +system build dependencies|   822MB |
| +Apache Kafka, HBase and Spark|    1.39GB  |
| +Python dependencies|  3.62GB    |

With a multi-stage build, and some optimisation on the Python side:

|        | size | Comment |
|--------|------|---------|
| prod   |  3.62GB    | Default
| prod + hard multi-stage   |  2.75GB  | No Java available |
| prod + soft multi-stage   |  3.15GB  | Java available |

With the hard multi-stage (i.e. we do not include any of the system build dependencies), we save 1GB. But the image is useless as we cannot use java-based framework. With the soft multi-stage (i.e. we keep Java, but get rid of other system build dependencies), we save 500 MB.

The current versions use the soft multi-stage strategy (about 3GB).

Todo:
- [ ] Inspect better Python dependencies.

### Start a container

```bash
# Build and run a container based on the ZTF development image
./build-images.sh -t ztf --tag dev --run

# Or run an existing image
docker run -it --rm dev bash
```

Note that when starting a container, a script is launched to automatically start Apache HBase and Apache Kafka. Several environment variables are already defined inside the container (see each Dockerfile specifically).

### Deploy images

See https://docs.docker.com/docker-hub/repos/#pushing-a-docker-container-image-to-docker-hub.

Example:

```bash
$ docker images
REPOSITORY                TAG       IMAGE ID       CREATED          SIZE
julienpeloton/fink-ci     dev       d5ee1c3b1299   20 minutes ago   3.15GB

$ docker push julienpeloton/fink-ci:dev
The push refers to repository [docker.io/julienpeloton/fink-ci]
d3eeb8e94cd6: Pushed
970209ec3e0c: Pushed
529806cc03af: Pushed
174f56854903: Mounted from library/centos
```

### Create your own image

To create your own image with specific versions, you can:

1. **For local development images**: Create a new folder (similar to `ztf` or `rubin`) with:
   - A `Dockerfile`
   - A `deps/` directory containing the requirements files
   - Build using: `./build-images.sh -t <folder_name> --tag <whatever>`

2. **For K8s images**: Modify `Dockerfile.k8s` and the dependencies in `common/deps/` or specific survey deps.

3. **For CI/CD**: The GitHub workflows automatically build and test images on push/PR.

The unified build script now handles all build scenarios with proper argument validation.

## Image availability

We have deployed images in DockerHub ([julienpeloton/fink-ci](https://hub.docker.com/repository/docker/julienpeloton/fink-ci)), than can be used easily.
