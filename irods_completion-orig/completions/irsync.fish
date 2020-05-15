# tab completion for irsync

function __irsync_irods_suggestions
  set curArg (string replace --regex '^i:' '' (commandline --current-token))
  set dirName ''
  if string match --quiet --regex / $curArg
    set pathParts (string split --right --max 1 / $curArg)
    set dirName "$pathParts[1]"/
  end
  set entries (command ils $dirName)
  string replace --regex '^  (C- )?' '' $entries[2..-1] \
    | string replace --regex '^.*/(.*)' '${1}/' \
    | string replace --regex '^' "i:$dirName"
end


complete --command irsync --no-files \
  --arguments '(__irsync_irods_suggestions)' \
  --condition "string match --quiet --regex '^i:' (commandline --current-token)"
