# tab completion for iphybun

complete --command iphybun --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))'
