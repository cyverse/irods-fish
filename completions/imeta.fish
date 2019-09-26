# tab completion for imeta
#
# TODO determine allowed order or arguments
# TODO extend to cover options
# TODO make suggest appropriate arguments
# TODO make suggest multiple arguments, if applicable

#
# Helper Functions
#

function __imeta_tokenize_cmdline
  __irods_tokenize_cmdline hV ''
end


#
# Completions
#

# imeta -h
complete --command imeta --short-option h \
  --condition '__irods_no_args_condition (__imeta_tokenize_cmdline)' \
  --description 'shows help'

# imeta -V
complete --command imeta --short-option V \
  --condition '__imeta_tokenize_cmdline | __irods_missing -h -V' \
  --description 'very verbose'

# TODO imeta -v

# TODO imeta -z <zone>

# TODO imeta <command>
complete --command imeta --arguments '(__irods_exec_slow __irods_path_suggestions)' --no-files
