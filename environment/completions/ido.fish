# tab completion for ido

function __ido_suggestions
	set cmdTerms (commandline --cut-at-cursor --tokenize)

	if [ (count $cmdTerms) -eq 1 ]
		ienvs
	else
		set environ $cmdTerms[2]
		set cmd (string replace --regex -- '\s*ido\s+'"$environ"'\s+' '' (commandline))
		ido $environ complete "--do-complete='$cmd'"
	end
end


complete --command ido --no-files --arguments '(__ido_suggestions)'
