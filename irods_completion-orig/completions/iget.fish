# tab completion for iget

complete --command iget --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))' \
  --condition 'test (count (commandline --cut-at-cursor --tokenize)) -eq 1'
