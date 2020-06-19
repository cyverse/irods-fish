function __irods_mk_help_completions --argument-names cmd \
		--description 'creates the help completions for a given command'

	complete --command $cmd --short-option h --long-option help \
		--condition __irods_no_args_condition \
		--description 'shows help'

  complete --command $cmd --arguments '--help' --condition __irods_no_args_condition \
	  --description 'shows help'
end
