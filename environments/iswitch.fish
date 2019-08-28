function iswitch --argument-names environ \
    --description 'switches to the given iRODS environment'

  if [ (count $argv) -eq 0 ]
    printf 'Usage: iswitch ENVIRON\n' >&2
    printf 'Switch to using the iRODS environment ENVIRON. If ENVIRON is empty, i.e., '', the\n' >&2
    printf 'current environment is unset\n\n' >&2
    printf 'Call `ienvs` to list the available iRODS environments.\n' >&2
    return 1
  end

  if [ -z $environ ]
    set --erase IRODS_ENVIRONMENT_FILE
  else
    set ieFile $HOME/.irods/$environ.json

    if [ -e $eFile ]
      set --export --global IRODS_ENVIRONMENT_FILE $ieFile
    else
      printf 'The environment %s doesn\'t exist, or its file %s isn\'t readable.\n' \
          $environ $ieFile \
        >&2

      return 1
    end
  end
end
