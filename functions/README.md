# fish Functions

Here are some fish functions for working within multiple iRODS environments.


## The Functions

The function `ido` executes a command within the context of the given iRODS environment without
switching to that environment.

The function `ienv` lists the available iRODS environments.

The function `iswitch` switches to the given iRODS environment.


## Notes on Environments

The functions assume all environment files end in the `.json` file extension and are in the
`.irods/` directory under the user's home directory. They also assume that the name of the
environment is the base name of the corresponding environment file with the file extension removed.
For example, the name of the iRODS environment described by the file
`/home/user/.irods/rods@zone.json` would be `rods@zone`.

The functions work by manipulating the `IRODS_ENVIRONMENT_FILE` environment variable. In particular,
`iswitch` sets this variable to the file corresponding the environment name it is provided.

To prevent inadvertently having authenticating incorrectly after switching iRODS environments, it is
recommended that each environment have its own authentication file, i.e., the field
`irods_authentication_file` in the environment file is set to distinct file name for each
environment.
