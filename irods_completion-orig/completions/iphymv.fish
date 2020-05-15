# tab completion for iphymv

complete --command iphymv --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))'
