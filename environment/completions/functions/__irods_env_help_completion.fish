function __irods_env_help_completion --argument-names cmd \
    --description 'creates the help completions for a given command'

    complete --command $cmd --short-option h --long-option help \
        --condition "__irods_no_args_condition (__irods_tokenize_cmdline h '')" \
        --description 'shows help'

    complete --command $cmd --arguments --help \
        --condition "__irods_no_args_condition (__irods_tokenize_cmdline h '')" \
        --description 'shows help'
end
