# autocompletions for iswitch

complete --command iswitch --no-files

complete --command iswitch --short-option h --long-option help \
	--condition __irods_no_args_condition \
	--description 'shows help'
complete --command iswitch --arguments '-h' --condition __irods_no_args_condition \
	--description 'shows help'

complete --command iswitch --arguments '(ienvs)' --condition __irods_no_args_condition
