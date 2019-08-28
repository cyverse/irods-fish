# tab completion for irsync
#
# TODO extend to cover options
# TODO make suggest appropriate arguments
# TODO make suggest multiple local paths
# TODO make suggest at most one remote path

function __irsync_irods_path_suggestions
    printf ' \u23f3\x08\x08\x08' >&2
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
    printf '  \x08\x08' >&2
end

function __irsync_suggest_irods_path
  string match --quiet --regex '^i:' (commandline --current-token)
end

complete --command irsync \
  --condition '__irsync_suggest_irods_path' \
  --no-files --arguments '(__irsync_irods_path_suggestions)'
