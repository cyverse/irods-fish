# tab completions for ihelp

#
# Helper Functions
#

function __ihelp_tokenize_cmdline
  __irods_tokenize_cmdline ah ''
end


#
# Condition Functions
#

function __ihelp_no_args
  set args (__ihelp_tokenize_cmdline)
  switch (count $args)
    case 0
      return 0
    case 1
      test $args[1] = -
    case '*'
      return 1
  end
end


#
# Completions
#

complete --command ihelp --short-option h \
  --description 'shows help' \
  --condition '__ihelp_no_args' --exclusive

complete --command ihelp --short-option a \
  --description 'prints the help text for all the iCommands' \
  --condition '__ihelp_no_args' --exclusive

for helpEntry in (ihelp | string match --entire --regex -- '^[a-z]+ +- ')
  set --local entryParts (string split --max 1 -- - $helpEntry | string trim)

  complete --command ihelp --arguments $entryParts[1] \
    --description (string replace --all --regex '(\(.*?\)|\.$)' '' $entryParts[2]) \
    --condition 'test (count (commandline --cut-at-cursor --tokenize)) -eq 1'
end

complete --command ihelp --no-files
