# tab completion for ils

#
# Helper functions
#

function __ils_absolute_path --argument-names path
  string match --quiet /\* $path
end

function __ils_bundle_suggestion --argument-names curPath
  set zone (command ienv | string replace --filter --regex -- '^.*irods_zone_name - ' '')
  set bundlePath /$zone/bundle/
  if [ -z $curPath ]
    echo $bundlePath
  else
    set cwd (string trim --right --chars / (command ipwd))
    set --erase curAbsPath
    if __ils_absolute_path $curPath
      set curAbsPath $curPath
    else
      set curAbsPath $cwd/$curPath
    end
    if __ils_separable_paths $curAbsPath $bundlePath
      return 1
    end
    if [ (string length $curAbsPath) -lt (string length $bundlePath) ]
      if __ils_absolute_path $curPath
        echo $bundlePath
      else
        string replace "$cwd"/ '' $bundlePath
      end
    end
  end
end

function __ils_join_path
  string match --invert '' $argv | string join / | string replace --all --regex '/+' /
end

function __ils_split_path --argument-names path
  set --erase parts
  if string match --invert --quiet '*/*' $path
    set parts[1] ''
    set parts[2] $path
  else
    set parts (string split --right --max 1 / $path)
    if string match --quiet '/*' $path
      set parts[1] (__ils_join_path / $parts[1])
    end
  end
  printf '%s\n%s\n' $parts[1] $parts[2]
end

function __ils_collection_suggestions --argument-names sugBegin
  set sugBase ''
  if not __ils_absolute_path $sugBegin
    set sugBase (command ipwd)
  end
  set sugParts (__ils_split_path $sugBegin)
  set sugParent $sugParts[1]
  set sugColl $sugParts[2]
  set parent (__ils_join_path $sugBase $sugParent)
  set --erase relCollPat
  if [ -z $sugColl ]
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

function __ils_separable_paths --argument-names partialPath basePath
  set baseMatch (string sub --length (string length $partialPath) $basePath)
  string match --invert --quiet $baseMatch'*' $partialPath
end

function __ils_tokenize_cmdline
  __irods_tokenize_cmdline AhLlrVv t
end


#
# Condition Functions
#

function __ils_no_args
  set args (__ils_tokenize_cmdline)
  switch (count $args)
    case 0
      return 0
    case 1
      test $args[1] = -
    case '*'
      return 1
  end
end

function __ils_no_opts
  set args (__ils_tokenize_cmdline)
  for opt in $argv
    if contains -- $opt $args
      return 1
    end
  end
  return 0
end


#
# Suggestion Functions
#

function __ils_path_suggestions
  set args (__ils_tokenize_cmdline)
  set --erase suggestions
  if contains -- --bundle $args
    set suggestions (__ils_bundle_suggestion $args[-1])
    if [ $status -ne 0 ]
      return 0
    end
  end
  if [ (count $suggestions) -eq 0 ]
    if contains -- -r $args
      set suggestions (__irods_exec_slow __ils_collection_suggestions $args[-1])
    else
      set suggestions (__irods_path_suggestions)
    end
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

complete --command ils --short-option h \
  --description 'shows help' \
  --condition '__ils_no_args' --exclusive

complete --command ils --short-option A \
  --description 'ACL and inheritance format' \
  --condition '__ils_no_opts -A -h --bundle' --no-files

complete --command ils --short-option L \
  --description 'very long format' \
  --condition '__ils_no_opts -h -L -l --bundle' --no-files

complete --command ils --short-option l \
  --description 'long format' \
  --condition '__ils_no_opts -h -L -l --bundle' --no-files

complete --command ils --short-option r \
  --description 'recursive - show subcollections' \
  --condition '__ils_no_opts -h -r' --no-files

complete --command ils --short-option t \
  --description 'use a ticket to access collection information' \
  --condition '__ils_no_opts -h -t --bundle' --exclusive

complete --command ils --short-option V \
  --description 'very verbose' \
  --condition '__ils_no_opts -h -V -v --bundle' --no-files

complete --command ils --short-option v \
  --description 'verbose' \
  --condition '__ils_no_opts -h -V -v --bundle' --no-files

complete --command ils --long-option bundle \
  --description 'list the subfiles in the bundle file created by iphybun command' \
  --condition '__ils_no_opts -h -A -L -l -t -V -v --bundle' --no-files

complete --command ils --arguments '(__ils_path_suggestions)' \
  --condition \
    "string match --invert --quiet --regex -- '^-([AhLlrtVv]+\$|-?)' (commandline --current-token)" \
  --no-files
