# tab completion for iget
#
# TODO extend to cover options
# TODO make suggest appropriate arguments
# TODO make suggest multiple remote paths
# TODO make suggest at most one local path

function __iget_first_arg
  set cmd (commandline --cut-at-cursor --tokenize)
  test (count $cmd) -eq 1
end

complete --command iget \
  --condition '__iget_first_arg' --no-files --arguments '(__irods_path_suggestions)'
