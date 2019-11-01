# tab completion for imeta
# TODO verify spaces are handled correctly
# TODO document
# TODO if using argparse is successfuly, convert all other completions to using it.
# TODO remove any unused functions/__irods_*.

#
# Helper Functions
#

function __imeta_am_admin
  set userType (command iuserinfo | string replace --filter --regex '^type: ' '')
  test "$userType" = rodsadmin
end

function __imeta_cmdline_args
  set args (commandline --cut-at-cursor --tokenize) (commandline --cut-at-cursor --current-token)
  set --erase args[1]
  string join -- \n $args
end

function __imeta_eval_with_cmdline --argument-names needs_cmdline
  set cmdline (__imeta_cmdline_args)
  eval "$needs_cmdline '$cmdline'"
end

function __imeta_tokenize_cmdline
  function tokenize_arg --no-scope-shadowing --argument-names arg
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

function __imeta_parse_for --argument-names optSpec consumer cmdline
  set optSpecArray (string split -- ' ' $optSpec)
  set cmdTokens (__imeta_tokenize_cmdline $optSpecArray -- (string split -- ' ' $cmdline))
  set _curr_token $cmdTokens[-1]
  set --erase cmdTokens[-1]
  argparse --stop-nonopt --name imeta $optSpecArray -- $cmdTokens 2>&1 | read failMsg
  if test -z "$failMsg"
    set _unparsed_args $argv
    eval "$consumer"
  else
    set needsVal (string replace --filter --regex -- '.*Expected argument for option -' '' $failMsg)
    if test $status -eq 0
      # Try again, removing the last option to work around the issue where
      # _curr_token is the missing value argparse is complaining about.
      set --erase cmdTokens[-1]
      argparse --stop-nonopt --name imeta $optSpecArray -- $cmdTokens 2> /dev/null
      if test $status -ne 0
        false
      else
        eval set _flag_$needsVal
        set _unparsed_args $argv
        eval "$consumer"
      end
    else
      false
    end
  end
end

function __imeta_parse_main_for --argument-names consumer cmdline
  function opts
    fish_opt --short h
    fish_opt --short V
    fish_opt --short v
    fish_opt --short z --required
  end
  set optSpec (opts)
  __imeta_parse_for "$optSpec" $consumer $cmdline
end

function __imeta_parse_cmd_args_for --argument-names consumer cmdline
  function opts
    fish_opt --short C
    fish_opt --short d
    fish_opt --short R
    fish_opt --short u
  end
  set optSpec (opts)
  __imeta_parse_for "$optSpec" $consumer $cmdline
end

function __imeta_parse_any_cmd_for --argument-names consumer cmdline
  function condition --no-scope-shadowing --argument-names consumer
    if test (count $_unparsed_args) -eq 0
      false
    else
      set _unparsed_args $_unparsed_args $_curr_token
      set --erase _unparsed_args[1]
      __imeta_parse_cmd_args_for $consumer "$_unparsed_args"
    end
  end
  __imeta_parse_main_for "condition $consumer" $cmdline
end

function __imeta_parse_cmd_for --argument-names consumer cmd cmdline
  function cmd_condition --no-scope-shadowing --argument-names cmd consumer
    if test (count $_unparsed_args) -eq 0 -o "$_unparsed_args[1]" != "$cmd"
      false
    else
      set _unparsed_args $_unparsed_args $_curr_token
      set --erase _unparsed_args[1]
      __imeta_parse_cmd_args_for $consumer "$_unparsed_args"
    end
  end
  set escConsumer (string escape $consumer)
  __imeta_parse_main_for "cmd_condition $cmd $escConsumer" $cmdline
end


#
# Condition functions
#

# shared condition tests

function __imeta_no_cmd_args --no-scope-shadowing
  test (count $_unparsed_args) -eq 0
  and not set --query _flag_C
  and not set --query _flag_d
  and not set --query _flag_R
  and not set --query _flag_u
end

function __imeta_cmd_has_flag_with_num_args --no-scope-shadowing --argument-names flag argCnt
  set --query $flag
  and test (count $_unparsed_args) -eq "$argCnt"
end

function __imeta_cmd_needs_coll --no-scope-shadowing
  __imeta_cmd_has_flag_with_num_args _flag_C 0
end

function __imeta_cmd_needs_data --no-scope-shadowing
  __imeta_cmd_has_flag_with_num_args _flag_d 0
end

function __imeta_cmd_needs_resc --no-scope-shadowing
  __imeta_cmd_has_flag_with_num_args _flag_R 0
end

function __imeta_cmd_needs_user --no-scope-shadowing
  __imeta_cmd_has_flag_with_num_args _flag_u 0
end

# main conditions

function __imeta_no_cmd_or_help_cond --argument-names cmdline
  function condition --no-scope-shadowing
    test (count $_unparsed_args) -eq 0
    and not set --query _flag_h
  end
  __imeta_parse_main_for condition $cmdline
end

function __imeta_verbose_cond --argument-names cmdline
  function condition --no-scope-shadowing
    test (count $_unparsed_args) -eq 0
    and not set --query _flag_h
    and not set --query _flag_V
    and not set --query _flag_v
  end
  __imeta_parse_main_for condition $cmdline
end

function __imeta_zone_cond --argument-names cmdline
  function condition --no-scope-shadowing
    if set --query _flag_z
      test -z "$_flag_z"
    else
      test (count $_unparsed_args) -eq 0
      and not set --query _flag_h
    end
  end
  __imeta_parse_main_for condition $cmdline
end

# add conditions

function __imeta_add_flag_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_no_cmd_args add $cmdline
end

function __imeta_add_admin_flag_cond --argument-names cmdline
  __imeta_add_flag_cond $cmdline
  and __imeta_am_admin
end

function __imeta_add_coll_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_coll add $cmdline
end

function __imeta_add_data_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_data add $cmdline
end

function __imeta_add_resc_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_resc add $cmdline
end

function __imeta_add_user_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_user add $cmdline
end

# adda conditions

function __imeta_adda_cond --argument-names cmdline
  __imeta_no_cmd_or_help_cond $cmdline
  and __imeta_am_admin
end

function __imeta_adda_flag_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_no_cmd_args adda $cmdline
end

function __imeta_adda_coll_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_coll adda $cmdline
end

function __imeta_adda_coll_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_C 1' adda $cmdline
end

function __imeta_adda_coll_attr_val_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_C 2' adda $cmdline
end

function __imeta_adda_coll_avu_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_C 3' adda $cmdline
end

function __imeta_adda_data_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_data adda $cmdline
end

function __imeta_adda_data_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_d 1' adda $cmdline
end

function __imeta_adda_data_attr_val_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_d 2' adda $cmdline
end

function __imeta_adda_data_avu_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_d 3' adda $cmdline
end

function __imeta_adda_resc_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_resc adda $cmdline
end

function __imeta_adda_resc_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_R 1' adda $cmdline
end

function __imeta_adda_resc_attr_val_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_R 2' adda $cmdline
end

function __imeta_adda_resc_avu_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_R 3' adda $cmdline
end

function __imeta_adda_user_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_user adda $cmdline
end

function __imeta_adda_user_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_u 1' adda $cmdline
end

function __imeta_adda_user_attr_val_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_u 2' adda $cmdline
end

function __imeta_adda_user_avu_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_u 3' adda $cmdline
end

# addw conditions

function __imeta_addw_flag_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_no_cmd_args addw $cmdline
end

# cp conditions

function __imeta_cp_flag_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_no_cmd_args cp $cmdline
end

function __imeta_cp_admin_flag_cond --argument-names cmdline
  __imeta_cp_flag_cond $cmdline
  and __imeta_am_admin
end


#
# Suggestion functions
#

# XXX strip trailing / off collection suggestions. A bug in iRODS 4.1.10
#     prevents imeta from finding the collection when it ends in /. See
#     https://github.com/irods/irods/issues/4559. This is still present in
#     iRODS 4.2.6.
function __imeta_coll_args
  __irods_collection_suggestions | string trim --right --chars /
end

function __imeta_coll_attr_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attrPat $_curr_token%
    __irods_quest '%s' "select META_COLL_ATTR_NAME where META_COLL_ATTR_NAME like '$attrPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_coll_attr_val_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set valPat $_curr_token%
    __irods_quest '%s' \
      "select META_COLL_ATTR_VALUE
       where META_COLL_ATTR_NAME = '$attr' and META_COLL_ATTR_VALUE like '$valPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_coll_attr_val_unit_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set val $_unparsed_args[3]
    set unitPat $_curr_token%
    __irods_quest '%s' \
      "select META_COLL_ATTR_UNITS
       where META_COLL_ATTR_NAME = '$attr'
         and META_COLL_ATTR_VALUE = '$val'
         and META_COLL_ATTR_UNITS like '$unitPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_data_attr_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attrPat $_curr_token%
    __irods_quest '%s' "select META_DATA_ATTR_NAME where META_DATA_ATTR_NAME like '$attrPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_data_attr_val_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set valPat $_curr_token%
    __irods_quest '%s' \
      "select META_DATA_ATTR_VALUE
       where META_DATA_ATTR_NAME = '$attr' and META_DATA_ATTR_VALUE like '$valPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_data_attr_val_unit_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set val $_unparsed_args[3]
    set unitPat $_curr_token%
    __irods_quest '%s' \
      "select META_DATA_ATTR_UNITS
       where META_DATA_ATTR_NAME = '$attr'
         and META_DATA_ATTR_VALUE = '$val'
         and META_DATA_ATTR_UNITS like '$unitPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_resc_args
  __irods_quest '%s' 'select RESC_NAME'
end

function __imeta_resc_attr_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attrPat $_curr_token%
    __irods_quest '%s' "select META_RESC_ATTR_NAME where META_RESC_ATTR_NAME like '$attrPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_resc_attr_val_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set valPat $_curr_token%
    __irods_quest '%s' \
      "select META_RESC_ATTR_VALUE
       where META_RESC_ATTR_NAME = '$attr' and META_RESC_ATTR_VALUE like '$valPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_resc_attr_val_unit_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set val $_unparsed_args[3]
    set unitPat $_curr_token%
    __irods_quest '%s' \
      "select META_RESC_ATTR_UNITS
       where META_RESC_ATTR_NAME = '$attr'
         and META_RESC_ATTR_VALUE = '$val'
         and META_RESC_ATTR_UNITS like '$unitPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_user_args
  __irods_quest '%s' 'select USER_NAME'
end

function __imeta_user_attr_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attrPat $_curr_token%
    __irods_quest '%s' "select META_USER_ATTR_NAME where META_USER_ATTR_NAME like '$attrPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_user_attr_val_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set valPat $_curr_token%
    __irods_quest '%s' \
      "select META_USER_ATTR_VALUE
       where META_USER_ATTR_NAME = '$attr' and META_USER_ATTR_VALUE like '$valPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_user_attr_val_unit_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set val $_unparsed_args[3]
    set unitPat $_curr_token%
    __irods_quest '%s' \
      "select META_USER_ATTR_UNITS
       where META_USER_ATTR_NAME = '$attr'
         and META_USER_ATTR_VALUE = '$val'
         and META_USER_ATTR_UNITS like '$unitPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_zone_args
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
    '__irods_exec_slow __imeta_eval_with_cmdline __imeta_add_admin_flag_cond'
end

function __imeta_mk_add_flag_completions --argument-names opt description
  __imeta_mk_hyphen_completions $opt $description '__imeta_eval_with_cmdline __imeta_add_flag_cond'
end

function __imeta_mk_adda_flag_completions --argument-names opt description
  __imeta_mk_hyphen_completions $opt $description '__imeta_eval_with_cmdline __imeta_adda_flag_cond'
end

function __imeta_mk_cp_flag_completions --argument-names opt description
  __imeta_mk_hyphen_completions $opt $description '__imeta_eval_with_cmdline __imeta_cp_flag_cond'
end

complete --command imeta --no-files

__imeta_mk_hyphen_completions h 'shows help' '__imeta_eval_with_cmdline __imeta_no_cmd_or_help_cond'

complete --command imeta --short-option V \
  --condition '__imeta_eval_with_cmdline __imeta_verbose_cond' \
  --description 'very verbose'

complete --command imeta --short-option v \
  --condition '__imeta_eval_with_cmdline __imeta_verbose_cond' \
  --description verbose

# XXX imeta -(v|V)z doesn't make any suggestions. This is a bug in fish. See
#     https://github.com/fish-shell/fish-shell/issues/5127. Check to see if this
#     is still a problem after upgrading to fish 3.1+.
complete --command imeta --short-option z \
  --arguments '(__irods_exec_slow __imeta_zone_args)' --exclusive \
  --condition '__imeta_eval_with_cmdline __imeta_zone_cond' \
  --description 'work with the specified zone'

# add

complete --command imeta --arguments add \
  --condition '__imeta_eval_with_cmdline __imeta_no_cmd_or_help_cond' \
  --description 'add new AVU triple'

# add -C
__imeta_mk_add_flag_completions C 'to collection'
complete --command imeta --arguments '(__irods_exec_slow __imeta_coll_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_add_coll_cond'

# add -d
__imeta_mk_add_flag_completions d 'to data object'
complete --command imeta --arguments '(__irods_exec_slow __irods_path_suggestions)' \
  --condition '__imeta_eval_with_cmdline __imeta_add_data_cond'

# add -R
__imeta_mk_add_admin_flag_completions R 'to resource'
complete --command imeta --arguments '(__irods_exec_slow __imeta_resc_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_add_resc_cond'

# add -u
__imeta_mk_add_admin_flag_completions u 'to user'
complete --command imeta --arguments '(__irods_exec_slow __imeta_user_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_add_user_cond'

# adda

complete --command imeta --arguments adda \
  --condition '__irods_exec_slow __imeta_eval_with_cmdline __imeta_adda_cond' \
  --description 'administratively add new AVU triple'

# adda -C
__imeta_mk_adda_flag_completions C 'to collection'
complete --command imeta --arguments '(__irods_exec_slow __imeta_coll_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_coll_cond'
complete --command imeta \
  --arguments '(__irods_exec_slow __imeta_eval_with_cmdline __imeta_coll_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_coll_attr_cond' \
  --description 'existing for collections'
complete --command imeta \
  --arguments '(__irods_exec_slow __imeta_eval_with_cmdline __imeta_coll_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_coll_attr_val_cond' \
  --description 'existing for attribute'
complete --command imeta \
  --arguments '(__irods_exec_slow __imeta_eval_with_cmdline __imeta_coll_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_coll_avu_cond' \
  --description 'existing for attribute-value'

# adda -d
__imeta_mk_adda_flag_completions d 'to data object'
complete --command imeta --arguments '(__irods_exec_slow __irods_path_suggestions)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_data_cond'
complete --command imeta \
  --arguments '(__irods_exec_slow __imeta_eval_with_cmdline __imeta_data_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_data_attr_cond' \
  --description 'existing for data objects'
complete --command imeta \
  --arguments '(__irods_exec_slow __imeta_eval_with_cmdline __imeta_data_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_data_attr_val_cond' \
  --description 'existing for attribute'
complete --command imeta \
  --arguments '(__irods_exec_slow __imeta_eval_with_cmdline __imeta_data_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_data_avu_cond' \
  --description 'existing for attribute-value'

# adda -R
__imeta_mk_adda_flag_completions R 'to resource'
complete --command imeta --arguments '(__irods_exec_slow __imeta_resc_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_resc_cond'
complete --command imeta \
  --arguments '(__irods_exec_slow __imeta_eval_with_cmdline __imeta_resc_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_resc_attr_cond' \
  --description 'existing for resources'
complete --command imeta \
  --arguments '(__irods_exec_slow __imeta_eval_with_cmdline __imeta_resc_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_resc_attr_val_cond' \
  --description 'existing for attribute'
complete --command imeta \
  --arguments '(__irods_exec_slow __imeta_eval_with_cmdline __imeta_resc_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_resc_avu_cond' \
  --description 'existing for attribute-value'

# adda -u
__imeta_mk_adda_flag_completions u 'to_user'
complete --command imeta --arguments '(__irods_exec_slow __imeta_user_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_user_cond'
complete --command imeta \
  --arguments '(__irods_exec_slow __imeta_eval_with_cmdline __imeta_user_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_user_attr_cond' \
  --description 'existing for users'
complete --command imeta \
  --arguments '(__irods_exec_slow __imeta_eval_with_cmdline __imeta_user_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_user_attr_val_cond' \
  --description 'existing for attribute'
complete --command imeta \
  --arguments '(__irods_exec_slow __imeta_eval_with_cmdline __imeta_user_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_user_avu_cond' \
  --description 'existing for attribute-value'

# addw

complete --command imeta --arguments addw \
  --condition '__imeta_eval_with_cmdline __imeta_no_cmd_or_help_cond' \
  --description 'add new AVU triple using wildcards in name'
__imeta_mk_hyphen_completions d 'to data object' '__imeta_eval_with_cmdline __imeta_addw_flag_cond'

# cp

complete --command imeta --arguments cp \
  --condition '__imeta_eval_with_cmdline __imeta_no_cmd_or_help_cond' \
  --description 'copy AVUs from one item to another'

# cp -C
__imeta_mk_cp_flag_completions C 'from collection'
# TODO imeta cp -C (-d|-C|-R|-u) <from-collection> <to-entity>

# cp -d
__imeta_mk_cp_flag_completions d 'from data object'
# TODO imeta cp -d (-d|-C|-R|-u) <from-data-object> <to-entity>

# cp -R
__imeta_mk_hyphen_completions R 'from resource' \
  '__irods_exec_slow __imeta_eval_with_cmdline __imeta_cp_admin_flag_cond'
# TODO imeta cp -R (-d|-C|-R|-u) <from-resource> <to-entity>

# cp -u
__imeta_mk_hyphen_completions u 'from user' \
  '__irods_exec_slow __imeta_eval_with_cmdline __imeta_cp_admin_flag_cond'
# TODO imeta cp -u (-d|-C|-R|-u) <from-user> <to-entity>

# ls

complete --command imeta --arguments ls \
  --condition '__imeta_eval_with_cmdline __imeta_no_cmd_or_help_cond' \
  --description 'list existing AVUs'

# TODO imeta ls (-[l]d|-[l]C|-[l]R|-[l]u) <entity> [<attribute>]

# lsw

complete --command imeta --arguments lsw \
  --condition '__imeta_eval_with_cmdline __imeta_no_cmd_or_help_cond' \
  --description 'list existing AVUs using wildcards'

# TODO imeta lsw (-[l]d|-[l]C|-[l]R|-[l]u) <entity> [<attribute>]

# mod

complete --command imeta --arguments mod \
  --condition '__imeta_eval_with_cmdline __imeta_no_cmd_or_help_cond' \
  --description 'modify AVU'

# TODO imeta mod (-d|-C|-R|-u) <entity> <attribute> <value> [<unit>][n:<new-attribute>][v:<new-value>][u:<new-units>]

# qu

complete --command imeta --arguments qu \
  --condition '__imeta_eval_with_cmdline __imeta_no_cmd_or_help_cond' \
  --description 'query entities with matching AVUs'

# TODO imeta qu (-d|-C|-R|-u) <attribute> <op> <value> ...

# rm

complete --command imeta --arguments rm \
  --condition '__imeta_eval_with_cmdline __imeta_no_cmd_or_help_cond' \
  --description 'remove AVU'

# TODO imeta rm (-d|-C|-R|-u) <entity> <attribute> <value> [<units>]

# rmi

complete --command imeta --arguments rmi \
  --condition '__imeta_eval_with_cmdline __imeta_no_cmd_or_help_cond' \
  --description 'remove AVU by metadata id'

# TODO imeta rmi (-d|-C|-R|-u) <entity> <metadata-id>

# rmw

complete --command imeta --arguments rmw \
  --condition '__imeta_eval_with_cmdline __imeta_no_cmd_or_help_cond' \
  --description 'remove AVU using wildcards'

# TODO imeta rmw (-d|-C|-R|-u) <entity> <attribute> <value> [<units>]

# set

complete --command imeta --arguments set \
  --condition '__imeta_eval_with_cmdline __imeta_no_cmd_or_help_cond' \
  --description 'assign a single value'

# TODO imeta set (-d|-C|-R|-u) <entity> <attribute> <new-value> [<new-units>]

functions --erase \
  __imeta_mk_cp_flag_completions \
  __imeta_mk_adda_flag_completions \
  __imeta_mk_add_flag_completions \
  __imeta_mk_add_admin_flag_completions \
  __imeta_mk_hyphen_completions
