# Dockerfiles for Fink

This repository contains Dockerfiles used in the context of [Fink](https://github.com/astrolabsoftware/fink-broker). We mainly use these in the Continuous Integration of various repositories. We currently check all codes on 2 main OS: centos7 (production) and centos 9 stream (dev).

```bash
# build prod image
./build.sh --os centos7 --tag prod

# Enter the container for prod
./build.sh --run --tag prod
```

| | dev | prod |
|-|-----|------|
| OS | centos 9 stream| centos7|
| Spark | 3.1.3 | 2.4.7 |
| Hadoop | 3.2 | 2.7|
| Java |11 | 8|
| HBase | 2.4.10 | 2.2.7 |
| Kafka | 2.8.1 | 2.1.0 |
