# tab completions for ihelp

complete --command ihelp --no-files

__irods_help_completion ihelp

complete --command ihelp --short-option a \
  --description 'prints the help text for all the iCommands' \
  --condition "__irods_no_args_condition (__irods_tokenize_cmdline ah '')"

for helpEntry in (ihelp | string match --entire --regex -- '^[a-z]+ +- ')
  set --local entryParts (string split --max 1 -- - $helpEntry | string trim)

  complete --command ihelp --arguments $entryParts[1] \
    --description (string replace --all --regex '(\(.*?\)|\.$)' '' $entryParts[2]) \
    --condition 'test (count (commandline --cut-at-cursor --tokenize)) -eq 1'
end
