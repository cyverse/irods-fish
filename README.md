# fish Shell Support for iRODS

This project provides support for working with iRODS command line tools within the
[fish shell](https://fishshell.com/).


## Overview

The [`environment`](environment/README.md) folder contains functions that assist with working in
multiple iRODS environments.

The [`irods_completion-orig`](irods_completion-org/README.md) folder contains a port of Bruno
Bzeznik's bash script
[i-commands-auto.bash](https://github.com/irods/irods-legacy/blob/master/iRODS/irods_completion.bash)
to fish.

The [`icommands-completion`](icommands-completion/README.md) folder contains an incomplete set of
tab completions for iCommands. __They are not released__.


## Installation

irods-fish can be installed using a Debian or Red Hat package, or it can be done manually.


### Package-based installation

_Installation using a package requires root privileges._

On Debian and Red Hat systems, a package can be used to install irods-fish. To build the packages,
do the following.

```
prompt> package/build
```

The packages can be found in the root directory.


### Manual installation

See [environment installation](environment/README.md#installation) for instructions on manually
installing the environment related support. To manually install iCommands tab completions port, see
[tab completions port installation](irods_completion-orig/README.md#installation).
