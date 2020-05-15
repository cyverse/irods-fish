# tab completion for ibun

complete --command ibun --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))'
