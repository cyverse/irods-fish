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
  --condition '__iquest_no_opts -h -z' --exclusive

# TODO implement
# iquest [-z Zonename]

complete --command iquest --long-option no-page \
  --description 'do not prompt asking whether to continue or not' \
  --condition '__iquest_no_opts -h --no-page' --no-file

# TODO implement
# iquest selectionConditionString
# iquest [hint]
# iquest [format]

# TODO implement
# iquest --sql 'pre-defined SQL string' [format] [arguments]
# iquest attrs

complete --command iquest --no-files
