function ienvs \
	--description 'lists the available iRODS environments'

	function show_help
		echo "Usage: ienvs [-h|--help]
This command lists the names of the available iRODS environments. An environment
is defined by the contents of an iRODS environment file with the environment's
name being the base name of the file without the .json file extension.
Options are:
 -h | --help  displays this help"
	end

	argparse --name ienvs (fish_opt --short h --long help) -- $argv
	or begin
		show_help >&2
		return 1
	end

	if set --query _flag_h
		show_help
		return 0
	end

	basename --multiple --suffix .json (ls $HOME/.irods/*.json)
end
