# tab completion for ils

#
# Helper functions
#

function __ils_bundle_suggestion --argument-names curPath
  set zone (command ienv | string replace --filter --regex -- '^.*irods_zone_name - ' '')
  set bundlePath /$zone/bundle/
  if test -z "$curPath"
    echo $bundlePath
  else
    set cwd (string trim --right --chars / (command ipwd))
    set --erase curAbsPath
    if __irods_is_path_absolute $curPath
      set curAbsPath $curPath
    else
      set curAbsPath $cwd/$curPath
    end
    if __ils_separable_paths $curAbsPath $bundlePath
      return 1
    end
    if test (string length $curAbsPath) -lt (string length $bundlePath)
      if __irods_is_path_absolute $curPath
        echo $bundlePath
      else
        string replace "$cwd"/ '' $bundlePath
      end
    end
  end
end

function __ils_mk_path_absolute --argument-names path
  set canonicalPath (string trim --right --chars / $path)
  if __irods_is_path_absolute $canonicalPath
    echo $canonicalPath
  else
    echo (__irods_join_path (command ipwd) $canonicalPath)
  end
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

function __ils_suggest
  set args (__ils_tokenize_cmdline)
  if not echo $args | __irods_missing -h $argv
    false
  else
    not __irods_cmdline_needs_param_val -t $args
  end
end


#
# Suggestion Functions
#

function __ils_path_suggestions
  set args (__ils_tokenize_cmdline)
  set --erase suggestions
  if contains -- --bundle $args
    set suggestions (__ils_bundle_suggestion $args[-1])
    if test "$status" -ne 0
      return 0
    end
  end
  if test (count $suggestions) -eq 0
    if contains -- -r $args
      set suggestions (__irods_collection_suggestions)
    else
      set suggestions (__irods_path_suggestions)
    end
  end
  set --erase cmdLineCanonicalPaths
  if test (count $args) -gt 1
    for arg in $args[1..-2]
      if string match --quiet --regex -- '^[^-]' $arg
        set cmdLineCanonicalPaths $cmdLineCanonicalPaths (__ils_mk_path_absolute $arg)
      end
    end
  end
  for suggestion in $suggestions
    set canonicalSug (__ils_mk_path_absolute $suggestion)
    if not contains $canonicalSug $cmdLineCanonicalPaths
      echo $suggestion
    end
  end
end


#
# Completions
#

__irods_help_completion ils

complete --command ils --short-option A  \
  --condition '__ils_suggest -A --bundle' \
  --description 'ACL and inheritance format'

complete --command ils --short-option L \
  --condition '__ils_suggest -L -l --bundle' \
  --description 'very long format'

complete --command ils --short-option l \
  --condition '__ils_suggest -L -l --bundle' \
  --description 'long format'

complete --command ils --short-option r \
  --condition '__ils_suggest -r' \
  --description 'recursive - show subcollections'

complete --command ils --short-option t --exclusive \
  --condition '__ils_tokenize_cmdline | __irods_missing -h -t --bundle' \
  --description 'use a ticket to access collection information'

complete --command ils --short-option V \
  --condition '__ils_suggest -V -v --bundle' \
  --description 'very verbose'

complete --command ils --short-option v \
  --condition '__ils_suggest -V -v --bundle' \
  --description 'verbose'

complete --command ils --long-option bundle \
  --condition '__ils_tokenize_cmdline | __irods_missing -h -A -L -l -t -V -v --bundle' \
  --description 'list the subfiles in the bundle file created by iphybun command'

complete --command ils --arguments '(__irods_exec_slow __ils_path_suggestions)' \
  --condition '__ils_tokenize_cmdline | __irods_missing -h -t'

complete --command ils --no-files
