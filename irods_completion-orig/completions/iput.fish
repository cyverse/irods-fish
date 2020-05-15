# tab completion for iput

complete --command iput --no-files \
  --arguments '(__irods_path_suggestions (commandline --current-token))' \
  --condition 'test (count (commandline --cut-at-cursor --tokenize)) -gt 1'
