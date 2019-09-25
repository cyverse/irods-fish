# This function determines if a given logical iRODS path is absolute.

function __irods_is_path_absolute --argument-names path \
    --description 'checks if a give logical iRODS path is absolute'

  string match --quiet -- '/*' $path
end
