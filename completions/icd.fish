# tab completion for icd

#
# Helper Functions
#

function __icd_tokenize_cmdline
  __irods_tokenize_cmdline hVv ''
end


#
# Condition Functions
#

function __icd_suggest_path
  set tokens (__icd_tokenize_cmdline)
  if not echo $tokens | __irods_missing -h
    false
  else
    test (count (string match --ignore-case --invert -- -v $tokens)) -le 1
  end
end


#
# Completions
#

complete --command icd --no-files

__irods_help_completion icd

# icd <collection>
complete --command icd --arguments '(__irods_exec_slow __irods_collection_suggestions)' \
  --condition __icd_suggest_path

# icd -V <collection>
complete --command icd --short-option V \
  --condition '__icd_tokenize_cmdline | __irods_missing -h -V -v' \
  --description 'very verbose'

# icd -v <collection>
complete --command icd --short-option v \
  --condition '__icd_tokenize_cmdline | __irods_missing -h -V -v' \
  --description 'verbose'
