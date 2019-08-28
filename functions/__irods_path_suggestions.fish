function __irods_path_suggestions \
    --description 'suggests collections and data objects in iRODS'

  # Add hourglass to right of cursor
  printf ' \u23f3\x08\x08\x08' >&2

  set curArg (commandline --current-token)

  set dirName ''
  if string match --quiet --regex / $curArg
    set pathParts (string split --right --max 1 / $curArg)
    set dirName "$pathParts[1]"/
  end

  set entries (command ils $dirName)

  string replace --regex '^  (C- )?' '' $entries[2..-1] \
    | string replace --regex '^.*/(.*)' '${1}/' \
    | string replace --regex '^' "$dirName"

  # Remove hourglass
  printf '  \x08\x08' >&2
end
