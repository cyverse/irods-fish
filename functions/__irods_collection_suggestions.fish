# This function generates a set of collections in iRODS visible to the current
# user that begin with the provided argument. If the token is the beginning of
# a relative path or there isn't one, the suggested paths will all be relative
# the user's current working collection.

function __irods_collection_suggestions --argument-names sugBegin \
    --description 'generates a list of collection suggestions'

  function split_path --argument-names path
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

  set sugBase ''
  if not __irods_is_path_absolute $sugBegin
    set sugBase (command ipwd)
  end

  set sugParts (split_path $sugBegin)
  set sugParent $sugParts[1]
  set sugColl $sugParts[2]
  set parent (__irods_join_path $sugBase $sugParent)

  set --erase relCollPat
  if test -z "$sugColl"
    set relCollPat '_%'
  else
    set relCollPat $sugColl%
  end

  set collPat (__irods_join_path $parent $relCollPat)
  set filter '^'(__irods_join_path $sugBase '(.*)')

  __irods_quest '%s/' \
      "select COLL_NAME where COLL_PARENT_NAME = '$parent' and COLL_NAME like '$collPat'" \
    | string replace --filter --regex $filter '$1'
end
