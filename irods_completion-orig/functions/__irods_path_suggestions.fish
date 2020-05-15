# This function generates a set of collections and data objects in iRODS visible
# to the current user that begin with the provided argument on the. If the
# argument is the beginning of a relative path or there isn't one, the suggested
# paths will all be relative the user's current working collection.

function __irods_path_suggestions --argument-names sugBegin \
    --description 'suggests collections and data objects in iRODS'

  set pathParts (__irods_split_path $sugBegin)
  set dirName $pathParts[1]

  if string match --quiet --regex -- '[^/]$' $dirName
    set dirName $dirName/
  end

  command ils $dirName \
    | string replace --filter --regex '^  (C- )?' '' \
    | string replace --regex '^.*/(.*)' '${1}/' \
    | string replace --regex '^' $dirName
end
