# tab completion for irsync
#
# TODO extend to cover options
# TODO make suggest appropriate arguments
# TODO make suggest multiple local paths
# TODO make suggest at most one remote path

function __irods_suggestions
  set curArg (commandline --current-token | string replace --regex '^i:' '')
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

function __suggest_irods_path
  string match --quiet --regex '^i:' (commandline --current-token)
end

complete --command irsync \
  --condition __suggest_irods_path --no-files --arguments '(__irods_exec_slow __irods_suggestions)'
