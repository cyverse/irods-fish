# tab completion for icp

complete --command icp --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))'
