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
# Condition Functions
#

function __irm_suggest
  set args (__irm_tokenize_cmdline)
  if not echo $args | __irods_missing -h $argv
    false
  else
    not __irods_cmdline_needs_param_val -n $args
  end
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
  --condition '__irm_suggest -f' \
  --description 'immediate removal of data-objects without putting them in trash'

# TODO irm -r <collection>

# irm -U (<collection>|<data-object>)
complete --command irm --short-option U \
  --condition '__irm_suggest -U' \
  --description 'unregister the file or collection'

# irm -V (<collection>|<data-object>)
complete --command irm --short-option V \
  --condition '__irm_suggest -V -v' \
  --description 'very verbose'

# irm -v (<collection>|<data-object>)
complete --command irm --short-option v \
  --condition '__irm_suggest -V -v' \
  --description 'verbose'

# irm --empty (<collection>|<data-object>)
complete --command irm --long-option empty \
  --condition '__irm_suggest --empty' \
  --description 'removed a bundle file only if all the subfiles of the bundle have been removed'

# irm -n <repl-num> (<collection>|<data-object>)
complete --command irm --short-option n --exclusive \
  --condition '__irm_tokenize_cmdline | __irods_missing -h -n' \
  --description 'the replica to remove'
