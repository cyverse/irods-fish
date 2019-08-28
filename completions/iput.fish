# tab completion for iput
#
# TODO extend to cover options
# TODO make suggest appropriate arguments
# TODO make suggest multiple local paths
# TODO make suggest at most one remote path

function __iput_after_first_arg
  set cmd (commandline --cut-at-cursor --tokenize)
  test (count $cmd) -gt 1
end

complete --command iput \
  --condition '__iput_after_first_arg' --no-files --arguments '(__irods_path_suggestions)'
