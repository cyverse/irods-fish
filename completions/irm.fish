# tab completion for irm
#
# TODO make suggest multiple arguments, if applicable

#
# Helper Functions
#

function __irm_collection_suggestions --argument-names sugBegin
  set sugBase ''
  if not __ils_absolute_path $sugBegin
    set sugBase (command ipwd)
  end
  set sugParts (__ils_split_path $sugBegin)
  set sugParent $sugParts[1]
  set sugColl $sugParts[2]
  set parent (__ils_join_path $sugBase $sugParent)
  set --erase relCollPat
  if test -z "$sugColl"
    set relCollPat '_%'
  else
    set relCollPat $sugColl%
  end
  set collPat (__ils_join_path $parent $relCollPat)
  set filter '^'(__ils_join_path $sugBase '(.*)')
  command iquest --no-page '%s/' \
       "select COLL_NAME where COLL_PARENT_NAME = '$parent' and COLL_NAME like '$collPat'" \
    | string match --invert --regex '^CAT_NO_ROWS_FOUND:' \
    | string replace --filter --regex $filter '$1'
end

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
# Suggestion Functions
#

function __irm_path_suggestions
  set args (__irm_tokenize_cmdline)
  set --erase suggestions
  if contains -- -r $args
    set suggestions (__irods_exec_slow __irm_collection_suggestions $args[-1])
  else
    set suggestions (__irods_path_suggestions)
  end
  for suggestion in $suggestions
    if not contains $suggestion $args[1..-2]
      echo $suggestion
    end
  end
end


#
# Completions
#

complete --command irm --no-files

# irm -h
complete --command irm --short-option h \
  --condition '__irods_no_args_condition (__irm_tokenize_cmdline)' \
  --description 'shows help'

# irm (<collection>|<data-object>)
complete --command irm --arguments '(__irm_path_suggestions)' --condition __irm_suggest

# irm -f (<collection>|<data-object>)
complete --command irm --short-option f --condition '__irm_suggest -f' \
  --description 'immediate removal of data-objects without putting them in trash'

# irm -r <collection>
complete --command irm --short-option r --condition '__irm_suggest -r' \
  --description 'recursive - remove the whole subtree'

# irm -U (<collection>|<data-object>)
complete --command irm --short-option U --condition '__irm_suggest -U' \
  --description 'unregister the file or collection'

# irm -V (<collection>|<data-object>)
complete --command irm --short-option V --condition '__irm_suggest -V -v' \
  --description 'very verbose'

# irm -v (<collection>|<data-object>)
complete --command irm --short-option v --condition '__irm_suggest -V -v' \
  --description 'verbose'

# irm --empty (<collection>|<data-object>)
complete --command irm --long-option empty --condition '__irm_suggest --empty' \
  --description 'removed a bundle file only if all the subfiles of the bundle have been removed'

# irm -n <repl-num> (<collection>|<data-object>)
complete --command irm --short-option n --exclusive \
  --condition '__irm_tokenize_cmdline | __irods_missing -h -n' \
  --description 'the replica to remove'
