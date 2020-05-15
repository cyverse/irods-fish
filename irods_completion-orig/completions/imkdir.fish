# tab completion for imkdir

complete --command imkdir --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))'
