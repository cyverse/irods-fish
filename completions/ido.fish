# tab completion for ido

function __ido_suggestions
  if [ (count (commandline --cut-at-cursor --tokenize)) -eq 1 ]
    ienvs
  else
    # XXX Needs to switch to correct iRODS envirnoment before complete
    complete --do-complete=(string replace --regex -- '\s*ido\s+[^\s]+\s+' '' (commandline))
  end
end

complete --command ido --no-files --arguments '(__ido_suggestions)'
