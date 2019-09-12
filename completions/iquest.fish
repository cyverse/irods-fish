# tab completion for iquest

complete --command iquest --short-option h \
  --description 'shows help' \
  --condition '__irods_no_args_condition' --exclusive

# TODO implement
# iquest [-z Zonename] [--no-page] [hint] [format] selectConditionString

# TODO implement
# iquest --sql 'pre-defined SQL string' [format] [arguments]
# iquest attrs

complete --command iquest --no-files
