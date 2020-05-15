# tab completion for irm

complete --command irm --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))'
