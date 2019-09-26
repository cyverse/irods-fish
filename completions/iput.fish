# tab completion for iput
#
# TODO extend to cover options
# TODO make suggest appropriate arguments
# TODO make suggest multiple local paths
# TODO make suggest at most one remote path

complete --command iput --arguments '(__irods_exec_slow __irods_path_suggestions)' --no-files \
  --condition 'test (count (commandline --cut-at-cursor --tokenize)) -gt 1'
