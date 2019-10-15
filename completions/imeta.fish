# tab completion for imeta
# TODO verify spaces are handled correctly

#
# Helper Functions
#

function __imeta_am_admin
  set userType (command iuserinfo | string replace --filter --regex '^type: ' '')
  test "$userType" = rodsadmin
end

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


#
# Condition functions
#

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

function __imeta_add_condition --no-scope-shadowing \
    --argument-names condition
  if test (count $_unparsed_args) -eq 0 -o "$_unparsed_args[1]" != add
    false
  else
    set _unparsed_args $_unparsed_args $_curr_token
    set --erase _unparsed_args[1]
    __imeta_suggest_add $condition $_unparsed_args
  end
end

function __imeta_add_needs_flag --no-scope-shadowing
  test (count $_unparsed_args) -eq 0
  and not set --query _flag_C
  and not set --query _flag_d
  and not set --query _flag_R
  and not set --query _flag_u
end

function __imeta_add_needs_admin_flag --no-scope-shadowing
  __imeta_add_needs_flag
  and __imeta_am_admin
end

function __imeta_add_needs_coll --no-scope-shadowing
  test (count $_unparsed_args) -eq 0
  and set --query _flag_C
end

function __imeta_add_needs_data --no-scope-shadowing
  test (count $_unparsed_args) -eq 0
  and set --query _flag_d
end

function __imeta_add_needs_resource --no-scope-shadowing
  test (count $_unparsed_args) -eq 0
  and set --query _flag_R
end

function __imeta_add_needs_user --no-scope-shadowing
  test (count $_unparsed_args) -eq 0
  and set --query _flag_u
end

function __imeta_suggest_adda --no-scope-shadowing
  __imeta_no_cmd_or_help
  and __imeta_am_admin
end

function __imeta_adda_condition --no-scope-shadowing \
    --argument-names condition
  if test (count $_unparsed_args) -eq 0 -o "$_unparsed_args[1]" != adda
    false
  else
    set _unparsed_args $_unparsed_args $_curr_token
    set --erase _unparsed_args[1]
    __imeta_suggest_add $condition $_unparsed_args
  end
end

function __imeta_adda_needs_coll_attr --no-scope-shadowing
  test (count $_unparsed_args) -eq 1
  and set --query _flag_C
end

function __imeta_adda_needs_coll_attr_val --no-scope-shadowing
  test (count $_unparsed_args) -eq 2
  and set --query _flag_C
end

function __imeta_adda_needs_coll_avu --no-scope-shadowing
  test (count $_unparsed_args) -eq 3
  and set --query _flag_C
end

function __imeta_adda_needs_data_attr --no-scope-shadowing
  test (count $_unparsed_args) -eq 1
  and set --query _flag_d
end

function __imeta_adda_needs_data_attr_val --no-scope-shadowing
  test (count $_unparsed_args) -eq 2
  and set --query _flag_d
end


#
# Suggestion functions
#

# TODO filter by current token
function __imeta_coll_attr_suggestions
  __irods_quest '%s' 'select META_COLL_ATTR_NAME'
end

function __imeta_coll_attr_val_suggestions
  function mk_suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set valPat $_curr_token%
    __irods_quest '%s' \
      "select META_COLL_ATTR_VALUE
       where META_COLL_ATTR_NAME = '$attr' and META_COLL_ATTR_VALUE like '$valPat'"
  end
  __imeta_suggest __imeta_adda_condition mk_suggestions
end

function __imeta_coll_avu_suggestions
  function mk_suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set val $_unparsed_args[3]
    set unitPat $_curr_token%
    __irods_quest '%s' \
      "select META_COLL_ATTR_UNITS
       where META_COLL_ATTR_NAME = '$attr'
         and META_COLL_ATTR_VALUE = '$val'
         and META_COLL_ATTR_UNITS like '$unitPat'"
  end
  __imeta_suggest __imeta_adda_condition mk_suggestions
end

# XXX strip trailing / off collection suggestions. A bug in iRODS 4.1.10
#     prevents imeta from finding the collection when it ends in /. See
#     https://github.com/irods/irods/issues/4559. This is still present in
#     iRODS 4.2.6.
function __imeta_coll_suggestions
  __irods_collection_suggestions | string trim --right --chars /
end

# TODO filter by current token
function __imeta_data_attr_suggestions
  __irods_quest '%s' 'select META_DATA_ATTR_NAME'
end

function __imeta_data_attr_val_suggestions
  function mk_suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set valPat $_curr_token%
    __irods_quest '%s' \
      "select META_DATA_ATTR_VALUE
       where META_DATA_ATTR_NAME = '$attr' and META_DATA_ATTR_VALUE like '$valPat'"
  end
  __imeta_suggest __imeta_adda_condition mk_suggestions
end

function __imeta_resource_suggestions
  __irods_quest '%s' 'select RESC_NAME'
end

function __imeta_user_suggestions
  __irods_quest '%s' 'select USER_NAME'
end

function __imeta_zone_suggestions
  __irods_quest '%s' 'select ZONE_NAME'
end


#
# Completions
#

function __imeta_mk_hyphen_completions --argument-names opt description condition
  complete --command imeta --arguments "-$opt" --condition $condition --description $description
  complete --command imeta --short-option $opt --condition $condition --description $description
end

function __imeta_mk_add_admin_flag_completions --argument-names opt description
  __imeta_mk_hyphen_completions $opt $description \
    '__irods_exec_slow __imeta_suggest __imeta_add_condition __imeta_add_needs_admin_flag'
end

function __imeta_mk_add_flag_completions --argument-names opt description
  __imeta_mk_hyphen_completions $opt $description \
    '__imeta_suggest __imeta_add_condition __imeta_add_needs_flag'
end

function __imeta_mk_adda_flag_completions --argument-names opt description
  __imeta_mk_hyphen_completions $opt $description \
    '__imeta_suggest __imeta_adda_condition __imeta_add_needs_flag'
end

complete --command imeta --no-files

__imeta_mk_hyphen_completions h 'shows help' '__imeta_suggest __imeta_no_cmd_or_help'

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

# add -C
__imeta_mk_add_flag_completions C 'to collection'
complete --command imeta --arguments '(__irods_exec_slow __imeta_coll_suggestions)' \
  --condition '__imeta_suggest __imeta_add_condition __imeta_add_needs_coll'

# add -d
__imeta_mk_add_flag_completions d 'to data object'
complete --command imeta --arguments '(__irods_exec_slow __irods_path_suggestions)' \
  --condition '__imeta_suggest __imeta_add_condition __imeta_add_needs_data'

# add -R
__imeta_mk_add_admin_flag_completions R 'to resource'
complete --command imeta --arguments '(__irods_exec_slow __imeta_resource_suggestions)' \
  --condition '__imeta_suggest __imeta_add_condition __imeta_add_needs_resource'

# add -u
__imeta_mk_add_admin_flag_completions u 'to user'
complete --command imeta --arguments '(__irods_exec_slow __imeta_user_suggestions)' \
  --condition '__imeta_suggest __imeta_add_condition __imeta_add_needs_user'

# adda

complete --command imeta --arguments adda \
  --condition '__irods_exec_slow __imeta_suggest __imeta_suggest_adda' \
  --description 'administratively add new AVU triple'

# adda -C
__imeta_mk_adda_flag_completions C 'to collection'
complete --command imeta --arguments '(__irods_exec_slow __imeta_coll_suggestions)' \
  --condition '__imeta_suggest __imeta_adda_condition __imeta_add_needs_coll'
complete --command imeta --arguments '(__irods_exec_slow __imeta_coll_attr_suggestions)' \
  --condition '__imeta_suggest __imeta_adda_condition __imeta_adda_needs_coll_attr' \
  --description 'existing for collections'
complete --command imeta --arguments '(__irods_exec_slow __imeta_coll_attr_val_suggestions)' \
  --condition '__imeta_suggest __imeta_adda_condition __imeta_adda_needs_coll_attr_val' \
  --description 'existing for attribute'
complete --command imeta --arguments '(__irods_exec_slow __imeta_coll_avu_suggestions)' \
  --condition '__imeta_suggest __imeta_adda_condition __imeta_adda_needs_coll_avu' \
  --description 'existing for attribute-value'

# adda -d
__imeta_mk_adda_flag_completions d 'to data object'
complete --command imeta --arguments '(__irods_exec_slow __irods_path_suggestions)' \
  --condition '__imeta_suggest __imeta_adda_condition __imeta_add_needs_data'
complete --command imeta --arguments '(__irods_exec_slow __imeta_data_attr_suggestions)' \
  --condition '__imeta_suggest __imeta_adda_condition __imeta_adda_needs_data_attr' \
  --description 'existing for data objects'
complete --command imeta --arguments '(__irods_exec_slow __imeta_data_attr_val_suggestions)' \
  --condition '__imeta_suggest __imeta_adda_condition __imeta_adda_needs_data_attr_val' \
  --description 'existing for attribute'
# TODO imeta adda -d <data object> <attribute> <value> <units>

# adda -R
__imeta_mk_adda_flag_completions R 'to resource'
# TODO imeta adda -R <resource> <attribute> <value> [<units>]

# adda -u
__imeta_mk_adda_flag_completions u 'to_user'
# TODO imeta adda -u <user> <attribute> <value> [<units>]

# addw

complete --command imeta --arguments addw --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'add new AVU triple using wildcards in name'

# TODO imeta addw -d <entity> <attribute> <value> [<units>]

# cp

complete --command imeta --arguments cp --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'copy AVUs from one item to another'

# TODO imeta cp (-d|-C|-R|-u) (-d|-C|-R|-u) <from-entity> <to-entity>

# ls

complete --command imeta --arguments ls --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'list existing AVUs'

# TODO imeta ls (-[l]d|-[l]C|-[l]R|-[l]u) <entity> [<attribute>]

# lsw

complete --command imeta --arguments lsw --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'list existing AVUs using wildcards'

# TODO imeta lsw (-[l]d|-[l]C|-[l]R|-[l]u) <entity> [<attribute>]

# mod

complete --command imeta --arguments mod --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'modify AVU'

# TODO imeta mod (-d|-C|-R|-u) <entity> <attribute> <value> [<unit>][n:<new-attribute>][v:<new-value>][u:<new-units>]

# qu

complete --command imeta --arguments qu --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'query entities with matching AVUs'

# TODO imeta qu (-d|-C|-R|-u) <attribute> <op> <value> ...

# rm

complete --command imeta --arguments rm --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'remove AVU'

# TODO imeta rm (-d|-C|-R|-u) <entity> <attribute> <value> [<units>]

# rmi

complete --command imeta --arguments rmi --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'remove AVU by metadata id'

# TODO imeta rmi (-d|-C|-R|-u) <entity> <metadata-id>

# rmw

complete --command imeta --arguments rmw --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'remove AVU using wildcards'

# TODO imeta rmw (-d|-C|-R|-u) <entity> <attribute> <value> [<units>]

# set

complete --command imeta --arguments set --condition '__imeta_suggest __imeta_no_cmd_or_help' \
  --description 'assign a single value'

# TODO imeta set (-d|-C|-R|-u) <entity> <attribute> <new-value> [<new-units>]

functions --erase \
  __imeta_mk_adda_flag_completions \
  __imeta_mk_add_flag_completions \
  __imeta_mk_add_admin_flag_completions \
  __imeta_mk_hyphen_completions
