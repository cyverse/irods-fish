function __irods_path_suggestions \
    --description 'suggests collections and data objects in iRODS'

  function __suggestions
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
  end

  __irods_exec_slow __suggestions
end
