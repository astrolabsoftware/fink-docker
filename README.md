# Dockerfiles for Fink

This repository contains Dockerfiles used in the context of [Fink](https://github.com/astrolabsoftware/fink-broker). We mainly use these in the Continuous Integration of various repositories. We currently check all codes on 2 main OS: centos7 (production) and centos 9 stream (dev).

```bash
# build prod image
./build.sh --os centos7 --tag prod

# Enter the container for prod
./build.sh --run --tag prod
```

Todo:
- [ ] Rename `build.sh` into something more meaningful
- [ ] Add deploy mode in the script
- [ ] Add Dockerfile for dev on centos 9 stream
- [ ] add CI
