function ido --argument-names environ cmd \
		--description 'executes a command in the given iRODS environment without switching to it'

	if test (count $argv) -lt 2
		printf 'Usage: ido ENVIRON CMD [ARG]...\n' >&2
		printf 'Executes `CMD [ARG]...` in the iRODS environment ENVIRON\n\n' >&2
		printf 'Call `ienvs` to list the available iRODS environments.\n' >&2
		return 1
	end

	set cmd $argv[2..-1]
	fish --command "iswitch $environ; and $cmd"
end
