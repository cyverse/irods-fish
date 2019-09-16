# tab completion for iquest
#
# TODO support tab completion of general queries

#
# Helper Functions
#

function __iquest_tokenize_cmdline
  __irods_tokenize_cmdline h z
end

function __iquest_no_opts
  while read arg
    if contains -- $arg $argv
      return 1
    end
  end
  return 0
end


#
# Condition Functions
#

# TODO combine with __iquest_suggest_uppercase somehow
function __iquest_suggest_no_distinct
  set args (__iquest_tokenize_cmdline)
  set argCnt (count $args)
  if test $argCnt -le 1
    true
  else if echo $args | __iquest_no_opts -h --sql attrs upper uppercase no-distinct
    set idx 1
    while test $idx -lt $argCnt
      if command test "$args[$idx]" = '-z'
        set idx (math $idx + 1)
      else
        if test "$args[$idx]" != --no-page
          return 1
        end
      end
      set idx (math $idx + 1)
    end
    true
  else
    false
  end
end

function __iquest_suggest_spec_query
  set args (__iquest_tokenize_cmdline)
  if set sqlIdx (contains --index -- --sql $args)
    test "$sqlIdx" -eq (math (count $args) - 1)
  else
    false
  end
end

function __iquest_suggest_uppercase
  set args (__iquest_tokenize_cmdline)
  set argCnt (count $args)
  if test $argCnt -le 1
    true
  else if echo $args | __iquest_no_opts -h --sql attrs upper uppercase
    set idx 1
    while test $idx -lt $argCnt
      if command test "$args[$idx]" = '-z'
        set idx (math $idx + 1)
      else
        if test "$args[$idx]" != --no-page -a "$args[$idx]" != no-distinct
          return 1
        end
      end
      set idx (math $idx + 1)
    end
    true
  else
    false
  end
end

function __iquest_suggest_zone
  if __iquest_tokenize_cmdline | __iquest_no_opts -h --sql attrs
    set args (__iquest_tokenize_cmdline)
    if set zIdx (contains --index -- -z $args)
      test "$zIdx" -ge (math (count $args) - 1)
    else
      true
    end
  else
    false
  end
end


#
# Suggestion Functions
#

function __iquest_spec_query_suggestions
  # TODO replace awk with string manipulations
  iquest --sql ls | awk 'BEGIN { RS = "----\n"; FS = "\n" } { print $1 }'
end

function __iquest_zone_suggestions
  iquest --no-page '%s' 'select ZONE_NAME' | string match --invert 'CAT_NO_ROWS_FOUND:*'
end


#
# Completions
#

complete --command iquest --no-files

#
# iquest -h
#

complete --command iquest --short-option h \
  --condition '__irods_no_args_condition (__iquest_tokenize_cmdline)' \
  --description 'shows help'

#
# iquest [-z <zone>][--no-page][[no-distinct] [uppercase] [<format>]] <general-query>
#

# -z <zone> <general-query>
complete --command iquest --short-option z \
  --arguments '(__irods_exec_slow __iquest_zone_suggestions)' --exclusive \
  --condition '__iquest_suggest_zone' \
  --description 'the zone to query'

# --no-page <general-query>
complete --command iquest --long-option no-page --no-files \
  --condition '__iquest_tokenize_cmdline | __iquest_no_opts -h --sql attrs --no-page' \
  --description 'do not prompt asking whether to continue or not'

# no-distinct <general-query>
complete --command iquest --arguments no-distinct \
  --condition __iquest_suggest_no_distinct \
  --description 'show duplicate results'

# uppercase <general-query>
complete --command iquest --arguments uppercase \
  --condition __iquest_suggest_uppercase \
  --description 'convert predicate attributes to uppercase'

#
# iquest --sql <specific-query> [<argument>...]
#

# --sql <specific-query>
complete --command iquest --long-option sql --exclusive \
  --condition 'test (count (__iquest_tokenize_cmdline)) -le 1' \
  --description 'executes a specific query'

complete --command iquest \
  --arguments '(__irods_exec_slow __iquest_spec_query_suggestions)' --no-files \
  --condition '__iquest_suggest_spec_query'

#
# iquest attrs
#

complete --command iquest --arguments attrs \
  --condition 'test (count (__iquest_tokenize_cmdline)) -le 1' \
  --description 'list the attributes that can be queried'
