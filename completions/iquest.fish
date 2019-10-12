# tab completion for iquest
#
# TODO support tab completion of general queries

#
# Helper Functions
#

function __iquest_needs_zone
  __irods_cmdline_needs_param_val -z $argv
end

function __iquest_tokenize_cmdline
  __irods_tokenize_cmdline h z
end


#
# Condition Functions
#

function __iquest_suggest_no_distinct
  set args (__iquest_tokenize_cmdline)
  set argCnt (count $args)
  if test "$argCnt" -le 1
    true
  else if echo $args | __irods_missing -h --sql attrs upper uppercase no-distinct
    set idx 1
    while test "$idx" -lt $argCnt
      if command test "$args[$idx]" = '-z'
        if __iquest_needs_zone $args
          return 1
        else
          set idx (math $idx + 1)
        end
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

function __iquest_suggest_no_page
  set args (__iquest_tokenize_cmdline)
  if not echo $args | __irods_missing -h --sql attrs --no-page
    false
  else
    not __iquest_needs_zone $args
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
  else if echo $args | __irods_missing -h --sql attrs upper uppercase
    set idx 1
    while test $idx -lt $argCnt
      if command test "$args[$idx]" = '-z'
        if __iquest_needs_zone $args
          return 1
        else
          set idx (math $idx + 1)
        end
      else if command test "$args[$idx]" != --no-page -a "$args[$idx]" != no-distinct
        return 1
      end
      set idx (math $idx + 1)
    end
    true
  else
    false
  end
end

function __iquest_suggest_zone
  if __iquest_tokenize_cmdline | __irods_missing -h --sql attrs
    set args (__iquest_tokenize_cmdline)
    if set zIdx (contains --index -- -z $args)
      __iquest_needs_zone $args; and test "$args[-1]" != -
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
  set extractedName 0
  iquest --sql ls | while read line
    if test "$line" = ----
      set extractedName 0
    else if test "$extractedName" -eq 0
      echo $line
      set extractedName 1
    end
  end
end

function __iquest_zone_suggestions
  __irods_quest '%s' 'select ZONE_NAME'
end


#
# Completions
#

complete --command iquest --no-files

__irods_help_completion iquest

#
# iquest [-z <zone>][--no-page][[no-distinct] [uppercase] [<format>]] <general-query>
#

# -z <zone> <general-query>
complete --command iquest --short-option z \
  --arguments '(__irods_exec_slow __iquest_zone_suggestions)' --exclusive \
  --condition __iquest_suggest_zone \
  --description 'the zone to query'

# --no-page <general-query>
complete --command iquest --long-option no-page --no-files \
  --condition __iquest_suggest_no_page \
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
  --condition __iquest_suggest_spec_query

#
# iquest attrs
#

complete --command iquest --arguments attrs \
  --condition 'test (count (__iquest_tokenize_cmdline)) -le 1' \
  --description 'list the attributes that can be queried'
