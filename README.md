# irods-fish

This project provides support for working with iRODS command line tools within the fish shell.

The [functions](functions/README.md) folder contains a set of functions for working within
multiple iRODS environments.

The [completions](completions/README.md) folder contains a set of tab completions corresponding to
the irods-fish functions and iCommands.


## Installation

To install the functions and tab completions locally, they need to be copied into the
 `.config/fish/functions/` and `.config/fish/completions/` directories under the user's home
 directory, respectively. To install them system wide, they need to be copied into
`/etc/fish/functions/` and `/etc/fish/completions/`, respectively.


## Acknowledgment

The iCommands tab completions are derived from i-commands-auto.bash,
https://github.com/irods/irods-legacy/blob/master/iRODS/irods_completion.bash, by Bruno Bzeznik.
