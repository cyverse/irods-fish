# tab completion for imeta

#
# Helper Functions
#

function __imeta_tokenize_cmdline
  function tokenize_arg --no-scope-shadowing \
      --argument-names arg
    if string match --invert --quiet --regex -- '^-[^-]' $arg
      echo $arg
      set matched passthru
    else
      set optChars (string split -- '' (string trim --left --chars '-' -- $arg))
      while test (count $optChars) -gt 0
        set --erase matched
        for opt in $optSpec
          if test "$opt" = "$optChars[1]"
            set matched opt
            echo -- '-'$optChars[1]
            set --erase optChars[1]
            break
          else if test "$opt" = "$optChars[1]="
            set matched opt
            echo -- '-'$optChars[1]
            if test (count $optChars) -gt 1
              set matched val
              string join -- '' $optChars[2..-1]
            end
            set --erase optChars
            break
          end
        end
        if not set --query matched
          string join -- '' '-' $optChars
          set --erase optChars
        end
      end
    end
    test "$matched" = opt
  end
  if not set splitIdx (contains --index -- '--' $argv)
    return 1
  end
  test "$splitIdx" -gt 1
  and set optSpec $argv[1..(math $splitIdx - 1)]
  set --erase argv[1..$splitIdx]
  if test (count $argv) -gt 0
    for arg in $argv
      tokenize_arg $arg
    end
    test $status -eq 0
    and echo ''
  end
  return 0
end

function __imeta_suggest
  function cmdline_args
    set args (commandline --cut-at-cursor --tokenize) (commandline --cut-at-cursor --current-token)
    set --erase args[1]
    string join -- \n $args
  end
  function main_opts
    fish_opt --short h
    fish_opt --short V
    fish_opt --short v
    fish_opt --short z --required
  end
  set condition $argv
  set optSpec (main_opts)
  set cmdTokens (__imeta_tokenize_cmdline $optSpec -- (cmdline_args))
  set _curr_token $cmdTokens[-1]
  set --erase cmdTokens[-1]
  argparse --stop-nonopt --name imeta $optSpec -- $cmdTokens 2>&1 | read failMsg
  if test -z "$failMsg"
    set _unparsed_args $argv
    eval "$condition"
  else
    set needsVal (string replace --filter --regex -- '.*Expected argument for option -' '' $failMsg)
    if test $status -eq 0
      # Try again, removing the last option to work around the issue where
      # _curr_token is the missing value argparse is complaining about.
      set --erase cmdTokens[-1]
      argparse --stop-nonopt --name imeta $optSpec -- $cmdTokens 2> /dev/null
      if test $status -ne 0
        false
      else
        eval set _flag_$needsVal
        set _unparsed_args $argv
        eval "$condition"
      end
    else
      false
    end
  end
end

function __imeta_suggest_add --argument-names condition
  function add_opts
    fish_opt --short C
    fish_opt --short d
    fish_opt --short R
    fish_opt --short u
  end
  set --erase argv[1]
  set optSpec (add_opts)
  set cmdTokens (__imeta_tokenize_cmdline $optSpec -- $argv)
  set _curr_token $cmdTokens[-1]
  set --erase cmdTokens[-1]
  if argparse --stop-nonopt --name imeta $optSpec -- $cmdTokens 2> /dev/null 
    set _unparsed_args $argv
    eval "$condition"
  else
    false
  end
end

function __imeta_add_condition --no-scope-shadowing \
    --argument-names adminReq condition
  function am_admin
    set userType (command iuserinfo | string replace --filter --regex '^type: ' '')
    test "$userType" = rodsadmin
  end
  if test "$adminReq" -ne 0
    if not __irods_exec_slow am_admin
      return 1
    end
  end
  if test (count $_unparsed_args) -eq 0 -o "$_unparsed_args[1]" != add
    false
  else
    set _unparsed_args $_unparsed_args $_curr_token
    set --erase _unparsed_args[1]
    __imeta_suggest_add $condition $_unparsed_args 
  end
end


#
# Condition functions
#

function __imeta_add_needs_collection --no-scope-shadowing
  test (count $_unparsed_args) -eq 0
  and set --query _flag_C
end

function __imeta_add_needs_data_object --no-scope-shadowing
  test (count $_unparsed_args) -eq 0
  and set --query _flag_d
end

function __imeta_add_needs_entity_flag --no-scope-shadowing
  test (count $_unparsed_args) -eq 0
  and not set --query _flag_C
  and not set --query _flag_d
  and not set --query _flag_R
  and not set --query _flag_u
end

function __imeta_add_needs_resource --no-scope-shadowing
  test (count $_unparsed_args) -eq 0
  and set --query _flag_R
end

function __imeta_no_cmd_or_help --no-scope-shadowing
  test (count $_unparsed_args) -eq 0
  and not set --query _flag_h
end

function __imeta_verbose_condition --no-scope-shadowing
  __imeta_no_cmd_or_help
  and not set --query _flag_V
  and not set --query _flag_v
end

function __imeta_zone_condition --no-scope-shadowing
  if set --query _flag_z
    test -z "$_flag_z"
  else
    __imeta_no_cmd_or_help
  end
end


#
# Suggestion functions
#

function __imeta_resource_suggestions
  __irods_quest '%s' 'select RESC_NAME'
end

function __imeta_zone_suggestions
  __irods_quest '%s' 'select ZONE_NAME'
end


#
# Completions
#

function __imeta_mk_add_entity_completions --argument-names opt adminReq description
  complete --command imeta --arguments '-'$opt \
    --condition "__imeta_suggest __imeta_add_condition $adminReq __imeta_add_needs_entity_flag" \
    --description $description
  complete --command imeta --short-option $opt \
    --condition "__imeta_suggest __imeta_add_condition $adminReq __imeta_add_needs_entity_flag" \
    --description $description
end

complete --command imeta --no-files

complete --command imeta --arguments '-h' --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'shows help'
complete --command imeta --short-option h --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'shows help'

complete --command imeta --short-option V --condition '__imeta_suggest __imeta_verbose_condition' \
  --description 'very verbose'

complete --command imeta --short-option v --condition '__imeta_suggest __imeta_verbose_condition' \
  --description verbose

# XXX imeta -(v|V)z doesn't make any suggestions. This is a bug in fish. See
#     https://github.com/fish-shell/fish-shell/issues/5127. Check to see if this
#     is still a problem after upgrading to fish 3.1+.
complete --command imeta --short-option z \
  --arguments '(__irods_exec_slow __imeta_zone_suggestions)' --exclusive \
  --condition '__imeta_suggest __imeta_zone_condition' \
  --description 'work with the specified zone'

# add
complete --command imeta --arguments add --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'add new AVU triple'

__imeta_mk_add_entity_completions C 0 'to collection'

complete --command imeta --arguments '(__irods_exec_slow __irods_collection_suggestions)' \
  --condition '__imeta_suggest __imeta_add_condition 0 __imeta_add_needs_collection'

__imeta_mk_add_entity_completions d 0 'to data object'

complete --command imeta --arguments '(__irods_exec_slow __irods_path_suggestions)' \
  --condition '__imeta_suggest __imeta_add_condition 0 __imeta_add_needs_data_object'

__imeta_mk_add_entity_completions R 1 'to resource'

complete --command imeta --arguments '(__irods_exec_slow __imeta_resource_suggestions)' \
  --condition '__imeta_suggest __imeta_add_condition 1 __imeta_add_needs_resource'

__imeta_mk_add_entity_completions u 1 'to user'

# TODO imeta add -u <user> <attribute> <value> [<unit>]

# imeta adda
complete --command imeta --arguments adda --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'administratively add new AVU triple'

# TODO imeta adda (-d|-C|-R|-u) <entity> <attribute> <value> [<units>]

# imeta addw
complete --command imeta --arguments addw --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'add new AVU triple using wildcards in name'

# TODO imeta addw -d <entity> <attribute> <value> [<units>]

# imeta cp
complete --command imeta --arguments cp --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'copy AVUs from one item to another'

# TODO imeta cp (-d|-C|-R|-u) (-d|-C|-R|-u) <from-entity> <to-entity>

# imeta ls
complete --command imeta --arguments ls --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'list existing AVUs'

# TODO imeta ls (-[l]d|-[l]C|-[l]R|-[l]u) <entity> [<attribute>]

# imeta lsw
complete --command imeta --arguments lsw --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'list existing AVUs using wildcards'

# TODO imeta lsw (-[l]d|-[l]C|-[l]R|-[l]u) <entity> [<attribute>]

# imeta mod
complete --command imeta --arguments mod --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'modify AVU'

# TODO imeta mod (-d|-C|-R|-u) <entity> <attribute> <value> [<unit>][n:<new-attribute>][v:<new-value>][u:<new-units>]

# imeta qu
complete --command imeta --arguments qu --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'query entities with matching AVUs'

# TODO imeta qu (-d|-C|-R|-u) <attribute> <op> <value> ...

# imeta set
complete --command imeta --arguments set --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'assign a single value'

# TODO imeta set (-d|-C|-R|-u) <entity> <attribute> <new-value> [<new-units>]

# imeta rm
complete --command imeta --arguments rm --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'remove AVU'

# imeta rmi
complete --command imeta --arguments rmi --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'remove AVU by metadata id'

# TODO imeta rmi (-d|-C|-R|-u) <entity> <metadata-id>

# TODO imeta rm (-d|-C|-R|-u) <entity> <attribute> <value> [<units>]

# imeta rmw
complete --command imeta --arguments rmw --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'remove AVU using wildcards'

# TODO imeta rmw (-d|-C|-R|-u) <entity> <attribute> <value> [<units>]

functions --erase __imeta_mk_add_entity_completions
