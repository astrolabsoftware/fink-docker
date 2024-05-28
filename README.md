# Dockerfile for Fink

This repository contains the Dockerfile to build all-in-one image for Fink. For k8s deployment, see https://github.com/astrolabsoftware/fink-broker instead.

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
| Spark | 3.1.3 |
| Hadoop | 3.2 |
| Java |11 |
| HBase | 2.4.10 |
| Kafka | 2.8.1 |

The production environment is currently in use at VirtualData, Université Paris-Saclay, to process the ZTF alert stream. For development purposes, one can also build locally the image using the wrapper:

```bash
./fink_docker -h
Build Dockerfile image for Fink

 Usage:
 ./fink_docker [-h]
 ./fink_docker --build [--os] [--tag]
 ./fink_docker --run [--tag]

 Specify the name of a folder with a Dockerfile with the option --os.
 Use --build to build the image from the Dockerfile in --os, with a tag (--tag).
 Use --run with a tag (--tag) to enter the container instead
 For the deployment, you need to have credentials defined.
 Use -h to display this help.
```

where the argument to `--os` is a folder containing necessary files (copy and modify `bin` for your purposes -- see below).

### Building an image

To build an image from a specific Dockerfile, use:

```bash
# e.g. build the prod image based on AlmaLinux 9
# and name it prod
./fink_docker --build --os bin --tag dev
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
# Enter a container based on the prod image
./fink_docker --run --tag dev
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

To create your own image with the versions you want, you would create a new folder, and copy files from an existing one (`centos7` or `centos9stream`). Then modify the values in the `ARG` in the Dockerfile. Change the base image if you wish. And then build it using:

```bash
./fink_docker --build --os <folder_name> --tag <whatever>
```

Todo:
- [ ] Allow `--build-arg` to be used from the CLI

## Image availability

We have deployed images in DockerHub ([julienpeloton/fink-ci](https://hub.docker.com/repository/docker/julienpeloton/fink-ci)), than can be used easily.
