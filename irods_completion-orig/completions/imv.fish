# tab completion for imv

complete --command imv --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))'
