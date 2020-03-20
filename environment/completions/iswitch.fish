# autocompletions for iswitch


function __iswitch_no_args
	test (count (commandline --cut-at-cursor --tokenize)) -eq 1
end


complete --command iswitch --no-files

complete --command iswitch --arguments '-h' --condition __iswitch_no_args --description 'shows help'
complete --command iswitch --short-option h --long-option help --condition __iswitch_no_args \
	--description 'shows help'

complete --command iswitch --arguments '(ienvs)' --condition __iswitch_no_args
