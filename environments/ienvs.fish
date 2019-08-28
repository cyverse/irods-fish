function ienvs \
    --description 'lists the available iRODS environments'

  basename --multiple --suffix .json (ls $HOME/.irods/*.json)
end
