# tab completion for imeta
#
# TODO determine allowed order or arguments
# TODO extend to cover options
# TODO make suggest appropriate arguments
# TODO make suggest multiple arguments, if applicable

# imeta -h
complete --command imeta --short-option h \
  --condition "__irods_no_args_condition (__irods_tokenize_cmdline hV '')" \
  --description 'shows help'

# TODO imeta -V
complete --command imeta --short-option V \
  --condition "__irods_tokenize_cmdline hV '' | __irods_missing -h -V" \
  --description 'very verbose'

# TODO imeta -v

# TODO imeta -z <zone>

# TODO imeta <command>
complete --command imeta --arguments '(__irods_exec_slow __irods_path_suggestions)' --no-files
