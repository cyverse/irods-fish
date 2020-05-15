# tab completion for irmtrash

complete --command irmtrash --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))'
