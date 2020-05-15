# tab completion for imeta

complete --command imeta --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))'
