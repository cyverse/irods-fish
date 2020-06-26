# tab completion for ido

function __ido_environ_suggestions

	if [ (count $argv) -eq 0 ]
	or [ (count $argv) -eq 1 -a $argv[1] != '' ]
		ienvs
	else
		if [ $argv[1] != -h ]
		and [ $argv[1] != --help ]
			set environ $argv[1]
			set cmd (string replace --regex -- '\s*ido\s+'"$environ"'\s+' '' (commandline))
			ido $environ complete "--do-complete='$cmd'" 2> /dev/null
		end
	end
end


complete --command ido --no-files
complete --command ido --arguments "(__ido_environ_suggestions (__irods_tokenize_cmdline h ''))"
__irods_env_help_completion ido
