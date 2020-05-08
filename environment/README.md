# Environment

Being able to switch between iRODS zones is useful for someone who works in multiple zones. This
package facilitates working in multiple zones or, more generally, with multiple iRODS environments.


## Overview

This package uses the base name of the iRODS environment file as the __name__ of the environment.
For example, for the environment file `.irods/irods_environment.json`, the name of the environment
would be `irods_environment`, and for `.irods/user@zone.json`, the name would be `user@zone`. This
package assumes all environment files end in with `.json` file extension and are in the `.irods`
directory under the user's home directory.

The functions in this package work by manipulating the `IRODS_ENVIRONMENT_FILE` environment
variable. In particular, `iswitch` sets this variable to the file corresponding to the provided
iRODS environment name.

___Warning:___ _To prevent inadvertently having authenticating incorrectly after switching
environments, each environment should have its own authentication file, i.e., the field
`irods_authentication_file` in each environment file should refer to a distinct authentication
file._


## Functions

This package provides three functions for working with iRODS environments. **`ienv`** lists the
available environments. **`iswitch`** switches to a given environment. Last, **`ido`** executes a
provided command within the context of a given environment without switching to it. Completion
support exists for each of these functions.


## Prompt

Here is some support for adding information about the current iRODS session to the command line
prompt.

When added to `fish_prompt`, the function **`irods_prompt`** displays the current iRODS environment
and working collection with the form `<env> <cwd>? `. `<env>` is the name of the environment and
`<cwd>` is the absolute path to the current working collection. The function substitutes `~` for
the absolute path to the iRODS user's home collection, and it abbreviates the name of every
collection in the path excluding the working collection to its first letter.

Here's an example. Pretend that the user's iRODS user name is `user`, and the name of the current
environment is `user@zone`. If the current working collection is
`/zone/home/user/path/to/collection`, then the generate prompt would be the
`user@zone ~/p/t/collection? `.

```
user@zone ~/p/t/collection? echo Hello, world!
Hello, world!
user@zone ~/p/t/collection?
```

The colors of the environment and current working collection tokens are customizable through
environment variables.

* **`irods_env_color`** defines the color of the environment token.
* **`irods_cwd_color`** defines the color of the current working collection token.


## Installation

irods-fish can be installed using a Debian package, or it can be done manually.

### Package-based installation

_Installation using a package requires root privileges._

On Debian and Red Hat systems, a package can be used to install irods-fish. To build the packages,
do the following.

```
prompt> package/build
```

The packages can be found in this directory (`environment/`).

### Manual installation

To install irods-fish manually, copy the contents of the directories `completions/functions/`,
`functions/`, and `prompt/` into `<base>/functions/` and the files `completions/*.fish` into
`<base>/completions/`. If installing for yourself, `<base>` is `$HOME/.config/fish`, otherwise
`/etc/fish`.
