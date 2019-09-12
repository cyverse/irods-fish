# This function checks to see if there are any arguments passed to a command. It
# allows a single "-" as the current token to allow tab completion to suggest
# options.

function __irods_no_args_condition \
    --description 'checks to see if the commandline as any arguments on it'

  set args (__irods_tokenize_cmdline '' '')

  switch (count $args)
    case 0
      return 0
    case 1
      test -z $args[1]; or test $args[1] = - 
    case '*'
      return 1
  end
end
