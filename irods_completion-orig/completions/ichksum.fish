# the tab completion for ichksum

complete --command ichksum --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))'
