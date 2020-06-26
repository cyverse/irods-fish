function __irods_icommand_help_completion --argument-names cmd \
    --description 'inject help completion for iCommand cmd'

  complete --command $cmd --short-option h \
    --condition "__irods_no_args_condition (__irods_tokenize_cmdline h '')" \
    --description 'shows help'
end
