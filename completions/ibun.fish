# tab completion for ibun
#
# TODO extend to cover options
# TODO make suggest appropriate arguments
# TODO make suggest multiple arguments, if applicable

function __ibun_arguments
  printf ' \u23f3\x08\x08\x08' >&2
  set curArg (commandline --current-token)
  if not string match --quiet --regex / $curArg
    set dirName ''
  else
    set pathParts (string split --right --max 1 / $curArg)
    set dirName "$pathParts[1]"/
  end
  set entries (ils $dirName)
  string replace --regex '^  (C- )?' '' $entries[2..-1] \
    | string replace --regex '^.*/(.*)' '${1}/' \
    | string replace --regex '^' "$dirName"
  printf '  \x08\x08' >&2
end

complete --command ibun --no-files --arguments '(__ibun_arguments)'
