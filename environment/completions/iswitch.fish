# autocompletions for iswitch

complete --command iswitch --no-files
complete --command iswitch --arguments '(ienvs)' --condition __irods_no_args_condition
__irods_mk_help_completions iswitch
