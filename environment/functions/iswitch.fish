function iswitch --argument-names environ \
		--description 'switches to the given iRODS environment'

	if test (count $argv) -eq 0
		printf 'Usage: iswitch ENVIRON\n'
		printf 'Switch to using the iRODS environment ENVIRON. If ENVIRON is empty, i.e., '', the\n'
		printf 'current environment is unset\n\n'
		printf 'Call `ienvs` to list the available iRODS environments.\n'
		return 1
	end >&2

	if test -z "$environ"
		set --erase IRODS_ENVIRONMENT_FILE
	else
		set ieFile $HOME/.irods/$environ.json

		if test -e "$ieFile"
			set --export --global IRODS_ENVIRONMENT_FILE $ieFile
		else
			printf 'The environment %s doesn\'t exist, or its file %s isn\'t readable.\n' \
					$environ $ieFile \
				>&2

			return 1
		end
	end
end
