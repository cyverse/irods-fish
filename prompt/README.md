# iRODS Prompt

Here is some support for adding information about the current iRODS session to the command line
prompt.

## `irods_prompt`

When added to `fish_prompt`, the function **`irods_prompt`** displays the current iRODS environment
and working collection with the form `<env> <cwd>? `. `<env>` is the same form displayed by `ienvs`,
and `<cwd>` is the absolute path to the current working collection. The function substitutes `~` for
the absolute path to the iRODS user's home collection, and it abbreviates the name of every
collection in the path excluding the working collection to its first letter.

Here's an example. Pretend that the user's iRODS user name is `user`, and the name of the current
environment is `user@tempZone`. If the current working collection is
`/tempZone/home/user/path/to/collection`, then the generate prompt would be the following.

```fish
user@tempZone ~/p/t/collection? echo Hello, world!
Hello, world!
user@tempZone ~/p/t/collection?
```

## Customization

The colors of the environment and current working collection tokens are customizable through
environment variables.

* **`irods_env_color`** defines the color of the environment token.
* **`irods_cwd_color`** defines the color of the current working collection token.
