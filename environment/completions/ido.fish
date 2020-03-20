# tab completion for ido

function __ido_no_args
	test (count (commandline --cut-at-cursor --tokenize)) -eq 1
end


function __ido_environ_suggestions
	set cmdTerms (commandline --cut-at-cursor --tokenize)

	if [ (count $cmdTerms) -eq 1 ]
		ienvs
	else
		if [ $cmdTerms[2] != -h ]
		and [ $cmdTerms[2] != --help ]
			set environ $cmdTerms[2]
			set cmd (string replace --regex -- '\s*ido\s+'"$environ"'\s+' '' (commandline))
			ido $environ complete "--do-complete='$cmd'"
		end
	end
end


complete --command ido --no-files

complete --command ido --arguments '-h' --condition __ido_no_args --description 'shows help'
complete --command ido --short-option h --long-option help --condition __ido_no_args \
	--description 'shows help'

complete --command ido --arguments '(__ido_environ_suggestions)'
