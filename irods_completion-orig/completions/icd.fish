# tab completion for icd

complete --command icd --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))'
