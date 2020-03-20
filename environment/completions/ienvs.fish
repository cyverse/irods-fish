# tab completion for ienvs

function __ienvs_no_args
	test (count (commandline --cut-at-cursor --tokenize)) -eq 1
end


complete --command ienvs --no-files

complete --command ienvs --arguments '-h' --condition __ienvs_no_args --description 'shows help'
complete --command ienvs --short-option h --long-option help --condition __ienvs_no_args \
	--description 'shows help'
