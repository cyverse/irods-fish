# tab completion for ido

function __ido_arguments
  set args (commandline --cut-at-cursor --tokenize)
  if [ (count $args) -eq 1 ]
    ienvs
  else
    set cmd (commandline | string replace --regex -- '\s*ido\s+[^\s]+\s+' '')
    complete --do-complete="$cmd"
  end
end

complete --command ido --no-files --arguments '(__ido_arguments)'
