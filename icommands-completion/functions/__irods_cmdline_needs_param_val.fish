# Given a parameter and a list of terms from a command line, this function
# checks to see if the last term is a value for the given parameter. The first
# argument should be the parameter with the remaining being the arguments passed
# to another command on the command line.

function __irods_cmdline_needs_param_val --argument-names param \
    --description "checks to see if the current term on command line is a parameter's value"

  if test (count $argv) -gt 1
    set cmdTerms $argv[2..-1]

    if set pIdx (contains --index -- $param $cmdTerms)
      test "$pIdx" -ge (math (count $cmdTerms) - 1)
    else
      false
    end
  else
    false
  end
end
