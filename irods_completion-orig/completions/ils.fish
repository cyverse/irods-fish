# tab completion for ils

complete --command ils --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))'
