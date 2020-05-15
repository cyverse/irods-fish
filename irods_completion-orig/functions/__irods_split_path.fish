# Given a path, it splits the path into two parts. The first is the path to
# the parent collection, and the second is the name. Neither the parent nor then
# entity need to exist. It returns a two element list, where the first element
# is the parent path and the second is the entity name.

function __irods_split_path --argument-names path \
    --description 'split path into parent path and entity name'

  set --erase parts
  if string match --invert --quiet -- '*/*' $path
    set parts[1] ''
    set parts[2] $path
  else
    set parts (string split --right --max 1 / $path)
    if string match --quiet '/*' $path
      set parts[1] (__irods_join_path / $parts[1])
    end
  end
  printf '%s\n%s\n' $parts[1] $parts[2]
end
