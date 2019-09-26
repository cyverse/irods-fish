# This function generates a set of collections and data objects in iRODS visible
# to the current user that begin with token currently being editted on the
# command line. If the token is the beginning of a relative path or there isn't
# one, the suggested paths will all be relative the user's current working
# collection.

function __irods_path_suggestions \
    --description 'suggests collections and data objects in iRODS'

  set curArg (commandline --current-token)

  set dirName ''
  if string match --quiet --regex -- / $curArg
    set pathParts (string split --right --max 1 / $curArg)
    set dirName "$pathParts[1]"/
  end

  set entries (command ils $dirName)

  string replace --regex '^  (C- )?' '' $entries[2..-1] \
    | string replace --regex '^.*/(.*)' '${1}/' \
    | string replace --regex '^' "$dirName"
end
