[![Build Status](https://cloud.drone.io/api/badges/DFabric/dppm-rest-api/status.svg)](https://cloud.drone.io/DFabric/dppm-rest-api)

# DPPM REST API

REST API for [DPPM](https://github.com/DFabric/dppm), an installer/manager of server applications.

## Development

You will need a [Crystal](https://crystal-lang.org) development environment.

You can either [install it](https://crystal-lang.org/docs/installation) or use a [Docker image](https://hub.docker.com/r/jrei/crystal-alpine).

### Compilation

Clone the repository and run:

`shards build`

The binary is `bin/dppm`

### Run tests

`crystal spec`

## Contributors

- [D. Scott Boggs](https://github.com/dscottboggs) - creator and maintainer
- [Julien Reichardt](https://github.com/j8r) - contributor and backer

## License

Copyright (c) 2018-2019 DFabric members - ISC License
