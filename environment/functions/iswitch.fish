function iswitch \
		--description 'switches to the given iRODS environment'

	function show_help
		echo 'Usage: iswitch [(-h|--help|ENVIRON)]
This command switches the iRODS environment to ENVIRON. If ENVIRON is empty or
not provided, the environment is unset.
Options are:
 -h | --help  displays this help'
	end

	argparse --name iswitch (fish_opt --short h --long help) -- $argv
	or begin
		show_help >&2
		return 1
	end

	if set --query _flag_h
		show_help
		return 0
	end

	set environ ''
	if [ (count $argv) -gt 0 ]
		set environ $argv[1]
	end

	if [ -z $environ ]
		not set --query IRODS_ENVIRONMENT_FILE
		or set --erase IRODS_ENVIRONMENT_FILE
	else
		set ieFile $HOME/.irods/$environ.json

		if [ -e "$ieFile" ]
			set --export --global IRODS_ENVIRONMENT_FILE $ieFile
		else
			printf 'The environment %s doesn\'t exist, or its file %s isn\'t readable.\n' \
					$environ $ieFile \
				>&2

			return 1
		end
	end
end
