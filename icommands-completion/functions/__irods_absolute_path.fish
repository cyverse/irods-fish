# Given a path to a collection or data object in iRODS, this function converts 
# the path to an absolute one.

function __irods_absolute_path --argument-names entity \
    --description 'converts relative iRODS path to absolute'

  if test -z $entity
    printf '%s/' (command ipwd)
  else if __irods_is_path_absolute $entity
    echo $entity
  else
    __irods_join_path (command ipwd) $entity
  end
end
