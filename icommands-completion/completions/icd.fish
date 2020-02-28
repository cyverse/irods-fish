# tab completion for icd

#
# Condition Functions
#

function __icd_suggest_path
  set tokens (__irods_tokenize_cmdline hVv '')
  if not echo $tokens | __irods_missing -h
    false
  else
    test (count (string match --ignore-case --invert -- -v $tokens)) -le 1
  end
end


#
# Completions
#

__irods_help_completion icd
__irods_verbose_completion icd "__irods_tokenize_cmdline hVv '' | __irods_missing -h -V -v"

complete --command icd \
  --arguments '(__irods_exec_slow __irods_collection_suggestions (commandline --current-token))' \
  --condition __icd_suggest_path

complete --command icd --no-files
