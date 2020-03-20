function ido \
		--description 'executes a command in the given iRODS environment without switching to it'

	function show_help
		echo 'Usage: ido (-h|--help|ENVIRON CMD ...)
This command executes (CMD ...) in the iRODS environment ENVIRON without
switching to it.
Options are:
 -h | --help  displays this help'
	end

	argparse --stop-nonopt --name ido (fish_opt --short h --long help) -- $argv
	or begin
		show_help >&2
		return 1
	end

	if set --query _flag_h
		show_help
		return 0
	end

	if [ (count $argv) -lt 2 ]
		show_help >&2
		return 1
	end

	set environ $argv[1]
	set cmd $argv[2..-1]
	fish --command "iswitch $environ; and $cmd"
end
