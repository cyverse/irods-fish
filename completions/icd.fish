# tab completion for icd
#
# TODO verify if order matters

# icd -h
complete --command icd --short-option h \
  --condition "__irods_no_args_condition (__irods_tokenize_cmdline h '')" \
  --description 'shows help'

# TODO icd [(-V|-v)] <collection>
# TODO restrict to collections
# TODO restrict to single path
complete --command icd --no-files --arguments '(__irods_path_suggestions)'
