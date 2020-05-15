# tab completion for itrim

complete --command itrim --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))'
