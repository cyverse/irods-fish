# tab completion for icd

#
# Helper Functions
#

function __icd_tokenize_cmdline
  __irods_tokenize_cmdline hVv ''
end


#
# Completions
#

# icd -h
complete --command icd --short-option h \
  --condition '__irods_no_args_condition (__icd_tokenize_cmdline)' \
  --description 'shows help'

# TODO restrict to collections
# TODO restrict to single path
# icd <collection>
complete --command icd --arguments '(__irods_path_suggestions)' --no-files

# icd -V <collection>
complete --command icd --short-option V \
  --condition '__icd_tokenize_cmdline | __irods_missing -h -V -v' \
  --description 'very verbose'

# icd -v <collection>
complete --command icd --short-option v \
  --condition '__icd_tokenize_cmdline | __irods_missing -h -V -v' \
  --description 'verbose'
