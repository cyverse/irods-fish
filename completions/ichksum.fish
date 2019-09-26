# tab completion for ichksum
#
# TODO extend to cover options
# TODO make suggest appropriate arguments
# TODO make suggest multiple arguments, if applicable

complete --command ichksum --arguments '(__irods_exec_slow __irods_path_suggestions)' --no-files 
