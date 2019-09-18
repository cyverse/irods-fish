# This function accepts a list of input parameters. It determines if all of
# those parameters are missing from its input. This is typically used to test if
# the current commandline of a command being tab completed contains any of a set
# of arguments. A completion test function would pipe the output of an
# __irods_tokenize_cmdline call into this function.

function __irods_missing \
    --description 'determines if a set of arguments are all missing from its input'

  while read arg
    if contains -- $arg $argv
      return 1
    end
  end

  return 0
end
