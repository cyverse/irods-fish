# tab completion for iget
#
# TODO extend to cover options
# TODO make suggest appropriate arguments
# TODO make suggest multiple remote paths
# TODO make suggest at most one local path

complete --command iget --no-files \
  --arguments '(__irods_exec_slow __irods_path_suggestions (commandline --current-token))' \
  --condition 'test (count (commandline --cut-at-cursor --tokenize)) -eq 1'
