# DPPM REST API

[![Build Status](https://cloud.drone.io/api/badges/DFabric/dppm-rest-api/status.svg)](https://cloud.drone.io/DFabric/dppm-rest-api)
[![Gitter](https://img.shields.io/badge/chat-on_gitter-red.svg?style=flat-square)](https://gitter.im/DFabric/Lobby)
[![ISC](https://img.shields.io/badge/License-ISC-blue.svg?style=flat-square)](https://en.wikipedia.org/wiki/ISC_license)

REST API for [DPPM](https://github.com/DFabric/dppm), an installer/manager of server applications.

## Documentation

https://dfabric.github.io/dppm-rest-api

## Development

You will need a [Crystal](https://crystal-lang.org) development environment.

You can either [install it](https://crystal-lang.org/docs/installation) or use a [Docker image](https://hub.docker.com/r/jrei/crystal-alpine).

### Compilation

Clone the repository and run:

`shards build`

The binary is `bin/dppm`

### Run tests

This runs the formatter, the linter, then the spec tests:

`crystal tool format && bin/ameba && crystal spec`

## Commands for setting permissions
The `dppm server` command has two subcommands for managing user permissions:
`user` and `group`. This API uses a role-based access model. That is, a user
itself does not have permissions, it is a member of a group (a role) which
then has a defined set of permissions.

A user has three attributes -- a name, for referring to the user directly;
an API key, for authentication; and a list of groups of which it is a member.

### Editing users

For the edit, rekey, show, and delete commands, the users may be selected
either by sepecifying a user's API key, if it is known, or by matching the name
and groups the user is a member of. It is not recommended to match only by name
or by groups, as your command may unintentionally affect similar users. For
example, two users may choose the same name, but be members of different
groups. This doesn't matter as they're only identified internally by their
API keys, but you may unintentionally add/remove groups from those users when
using this command in that situation.

Ideally, you won't have multiple users with the same name, or you can use the
web interface to edit these values using API keys for exact identification.

This can also be used for batch processing. For example, if you want to replace
one group with several more granular ones, you can add all members of the old
group to the new groups before deleting the old group.

#### Matching on users
You may use an exact match like `match-name=Scott`, or by using regex, like
`match-name='/(D\..)?Scott.Boggs\d{0,2}/'`. In either case, ANY matching user
is selected, so again, if there are multiple users with the same name, they
will *all* be selected.

#### Matching on groups
Group matches are non-exclusive -- that is, users may also be members of groups
*not* specified, but they must be a member of the specified groups. You may
specify several groups by separating them with commas, and multiple group
selectors by separating them with a colon, like `match-groups=1,2,3:2,4`, which
would select a user who's a member of groups 1, 2, and 3, or a user who's a member
of groups 2 and 4.

## Contributors

- [D. Scott Boggs](https://github.com/dscottboggs) - creator and maintainer
- [Julien Reichardt](https://github.com/j8r) - contributor and backer

## License

Copyright (c) 2018-2019 DFabric members - ISC License
