# tab completion for irm
#
# TODO make suggest appropriate arguments
# TODO make suggest multiple arguments, if applicable

#
# Helper Functions
#

function __irm_tokenize_cmdline
  __irods_tokenize_cmdline hfrUvV n
end


#
# Completions
#

# irm -h
complete --command irm --short-option h \
  --condition '__irods_no_args_condition (__irm_tokenize_cmdline)' \
  --description 'shows help'

# irm [-f] [-r] [-U] [(-v|-V)] [--empty] [-n <repl-num>] (<collection>|<data-object>)

# irm (<collection>|<data-object>)
complete --command irm --arguments '(__irods_path_suggestions)' --no-files

# irm -f (<collection>|<data-object>)
complete --command irm --short-option f \
  --condition '__irm_tokenize_cmdline | __irods_missing -h -f' \
  --description 'immediate removal of data-objects without putting them in trash'

# TODO irm -r <collection>

# irm -U (<collection>|<data-object>)
complete --command irm --short-option U \
  --condition '__irm_tokenize_cmdline | __irods_missing -h -U' \
  --description 'unregister the file or collection'

# TODO irm (-v|-V) (<collection>|<data-object>)
# TODO irm --empty (<collection>|<data-object>)
# TODO irm -n <repl-num> (<collection>|<data-object>)
