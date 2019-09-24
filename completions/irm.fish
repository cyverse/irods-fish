# tab completion for irm

#
# Helper Functions
#

function __irm_absolute_path --argument-names path
 string match --quiet -- /\* $path
end

function __irm_join_path
  string match --invert -- '' $argv | string join / | string replace --all --regex '/+' /
end

function __irm_mk_path_absolute --argument-names path
  set canonicalPath (string trim --right --chars / $path)
  if __irm_absolute_path $canonicalPath
    echo $canonicalPath
  else
    echo (__irm_join_path (command ipwd) $canonicalPath)
  end
end

function __irm_split_path --argument-names path
  set --erase parts
  if string match --invert --quiet -- '*/*' $path
    set parts[1] ''
    set parts[2] $path
  else
    set parts (string split --right --max 1 / $path)
    if string match --quiet '/*' $path
      set parts[1] (__irm_join_path / $parts[1])
    end
  end
  printf '%s\n%s\n' $parts[1] $parts[2]
end

function __irm_collection_suggestions --argument-names sugBegin
  set sugBase ''
  if not __irm_absolute_path $sugBegin
    set sugBase (command ipwd)
  end
  set sugParts (__irm_split_path $sugBegin)
  set sugParent $sugParts[1]
  set sugColl $sugParts[2]
  set parent (__irm_join_path $sugBase $sugParent)
  set --erase relCollPat
  if test -z "$sugColl"
    set relCollPat '_%'
  else
    set relCollPat $sugColl%
  end
  set collPat (__irm_join_path $parent $relCollPat)
  set filter '^'(__irm_join_path $sugBase '(.*)')
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
  set --erase cmdLineCanonicalPaths
  if test (count $args) -gt 1
    for arg in $args[1..-2]
      if string match --quiet --regex -- '^[^-]' $arg
        set cmdLineCanonicalPaths $cmdLineCanonicalPaths (__irm_mk_path_absolute $arg)
      end
    end
  end
  for suggestion in $suggestions
    set canonicalSug (__irm_mk_path_absolute $suggestion)
    if not contains $canonicalSug $cmdLineCanonicalPaths
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
