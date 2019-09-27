# This function injects a completion for both verbose and very verbose flags into the environment
# for a given command, applying the given condition that must be true for the completions to be
# suggested.

function __irods_verbose_completion --argument-names cmd condition \
    --description 'inject verbose and very verbose completions'

  complete --command $cmd --short-option V --condition $condition --description 'very verbose'
  complete --command $cmd --short-option v --condition $condition --description verbose
end
