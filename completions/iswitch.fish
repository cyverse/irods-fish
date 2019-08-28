# autocompletions for iswitch

function __iswitch_arguments
  set cmd (commandline --cut-at-cursor --tokenize)
  if [ (count $cmd) -eq 1 ]
    ienvs
  end
end

complete --command iswitch --no-files --arguments '(__iswitch_arguments)'
