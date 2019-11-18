# tab completion for ibun
#
# TODO extend to cover options
# TODO make suggest appropriate arguments
# TODO make suggest multiple arguments, if applicable

complete --command ibun --no-files \
  --arguments '(__irods_exec_slow __irods_path_suggestions (commandline --current-token))'
