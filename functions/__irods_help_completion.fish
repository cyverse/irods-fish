# This function injects a help completion into the environment for a given
# command.

function __irods_help_completion --argument-names cmd \
    --description 'inject help completion for command'

  complete --command $cmd --short-option h \
    --condition "__irods_no_args_condition (__irods_tokenize_cmdline h '')" \
    --description 'shows help'
end
