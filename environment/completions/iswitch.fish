# autocompletions for iswitch

function __iswitch_suggestions
  if test (count (commandline --cut-at-cursor --tokenize)) -eq 1
    ienvs
  end
end

complete --command iswitch --no-files --arguments '(__iswitch_suggestions)'
