# tab completion for imeta
#
# TODO determine allowed order or arguments
# TODO extend to cover options
# TODO make suggest appropriate arguments
# TODO make suggest multiple arguments, if applicable

#
# Helper Functions
#

function __imeta_needs_zone
  __irods_cmdline_needs_param_val -z $argv
end

function __imeta_tokenize_cmdline
  __irods_tokenize_cmdline hVv z
end


#
# Condition functions
#

function __imeta_suggest_zone
  set args (__imeta_tokenize_cmdline)
  if echo $args | __irods_missing -h
    if set zIdx (contains --index -- -z $args)
      __imeta_needs_zone $args; and test "$args[-1]" != -
    else
      true
    end
  else
    false
  end
end


#
# Suggestion functions
#

function __imeta_zone_suggestions
  iquest --no-page '%s' 'select ZONE_NAME' | string match --invert 'CAT_NO_ROWS_FOUND:*'
end


#
# Completions
#

__irods_help_completion imeta
__irods_verbose_completion imeta '__imeta_tokenize_cmdline | __irods_missing -h -V -v'

# imeta -z <zone>
complete --command imeta --short-option z \
--arguments '(__irods_exec_slow __imeta_zone_suggestions)' --exclusive \
--condition __imeta_suggest_zone \
--description 'work with the specified zone'

# TODO imeta <command>
complete --command imeta --arguments '(__irods_exec_slow __irods_path_suggestions)' --no-files
