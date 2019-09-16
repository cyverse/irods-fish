# tab completion for iquest

#
# Helper Functions
#

function __iquest_tokenize_cmdline
  __irods_tokenize_cmdline h z
end


#
# Condition Functions
#

function __iquest_no_opts
  set args (__iquest_tokenize_cmdline)
  for opt in $argv
    if contains -- $opt $args
      return 1
    end
  end
  true
end

function __iquest_suggest_zone
  if __iquest_no_opts -h --sql attrs
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
# iquest [-z <zone>][--no-page] [no-distinct] [uppercase] [<format>] <general-query>
#

# TODO <general-query>

# -z <zone> <general-query>
complete --command iquest --short-option z \
  --arguments '(__irods_exec_slow __iquest_zone_suggestions)' --exclusive \
  --condition '__iquest_suggest_zone' \
  --description 'the zone to query'

# --no-page <general-query>
complete --command iquest --long-option no-page --no-files \
  --condition '__iquest_no_opts -h --sql attrs --no-page' \
  --description 'do not prompt asking whether to continue or not'

# no-distinct <general-query>
complete --command iquest --arguments no-distinct \
  --description 'show duplicate results' \
  --condition '__iquest_no_opts -h --sql attrs upper uppercase no-distinct'

# uppercase <general-query>
complete --command iquest --arguments uppercase \
  --description 'convert predicate attributes to uppercase' \
  --condition '__iquest_no_opts -h --sql attrs upper uppercase'

# TODO <format> <general-query>

#
# iquest --sql <specific-query> [<format>] [<argument>...]
#

# --sql <specific-query>
# TODO suggest specific queries
complete --command iquest --long-option sql --exclusive \
  --condition 'test (count (__iquest_tokenize_cmdline)) -le 1' \
  --description 'executes a specific query'

# TODO --sql <specific-query> <format>
# TODO --sql <specific-query> <argument>...

#
# iquest attrs
#

complete --command iquest --arguments attrs \
  --description 'list the attributes that can be queried' \
  --condition 'test (count (__iquest_tokenize_cmdline)) -le 1'
