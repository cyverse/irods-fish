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
  __irods_tokenize_cmdline hVv ''
end


#
# Completions
#

__irods_help_completion imeta
__irods_verbose_completion imeta '__imeta_tokenize_cmdline | __irods_missing -h -V -v'

# TODO imeta -z <zone>

# TODO imeta <command>
complete --command imeta --arguments '(__irods_exec_slow __irods_path_suggestions)' --no-files
