# tab completion for ichmod

complete --command ichmod --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))'
