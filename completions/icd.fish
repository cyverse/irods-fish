# tab completion for icd

# icd -h
complete --command icd --short-option h \
  --condition "__irods_no_args_condition (__irods_tokenize_cmdline hV '')" \
  --description 'shows help'

# TODO restrict to collections
# TODO restrict to single path
# icd <collection>
complete --command icd --arguments '(__irods_path_suggestions)' --no-files

# icd -V <collection>
complete --command icd --short-option V \
  --condition "__irods_tokenize_cmdline hV '' | __irods_missing -h -V" \
  --description 'very verbose'

# TODO icd -v <collection>
