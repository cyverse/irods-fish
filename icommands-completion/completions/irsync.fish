# tab completion for irsync
#
# TODO extend to cover options
# TODO make suggest appropriate arguments
# TODO make suggest multiple local paths
# TODO make suggest at most one remote path

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

complete --command irsync \
  --condition "string match --quiet --regex '^i:' (commandline --current-token)" \
  --no-files --arguments '(__irods_exec_slow __irsync_irods_suggestions)'
