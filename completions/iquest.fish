# tab completion for iquest

#
# Condition Functions
#

function __iquest_no_opts
  set args (__irods_tokenize_cmdline hz '')
  for opt in $argv
    if contains -- $opt $args
      return 1
    end
  end
  return 0
end


#
# Completions
#

complete --command iquest --short-option h \
  --description 'shows help' \
  --condition '__irods_no_args_condition' --exclusive

complete --command iquest --short-option z \
  --description 'the zone to query' \
  --condition '__iquest_no_opts -h -z attrs' --exclusive

# TODO implement
# iquest [-z Zonename]

complete --command iquest --long-option no-page \
  --description 'do not prompt asking whether to continue or not' \
  --condition '__iquest_no_opts -h --no-page attrs' --no-file

# TODO implement
# iquest selectionConditionString
# iquest [hint] selectionConditionString
# iquest [hint] [format] selectionConditionString

complete --command iquest --long-option sql \
  --description 'executes a specific query' \
  --condition '__iquest_no_opts -h --sql attrs' --exclusive

# TODO implement
# iquest --sql 'pre-defined SQL string'
# iquest --sql 'pre-defined SQL string' [format]
# iquest --sql 'pre-defined SQL string' [format] [arguments]

complete --command iquest --arguments '(echo attrs)' \
  --condition '__irods_no_args_condition' --no-files

complete --command iquest --no-files
