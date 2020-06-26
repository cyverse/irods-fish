function __irods_no_args_condition \
		--description 'tests if the command line has any complete arguments after the command'

	test (count (commandline --cut-at-cursor --tokenize)) -eq 1
end
