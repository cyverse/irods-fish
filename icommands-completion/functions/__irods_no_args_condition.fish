# This function checks to see if there are any arguments passed to it. It allows
# a single "-" as the last argument to allow tab completion to suggest options.
# It is assumed that $argv will contain the arguments passed to another command
# on the command line.

# TODO make this version and the common version identical

function __irods_no_args_condition \
    --description 'checks to see if a command line has any arguments on it'

  switch (count $argv)
    case 0
      return 0
    case 1
      command test -z "$argv[1]" -o "$argv[1]" = '-'
    case '*'
      return 1
  end
end
