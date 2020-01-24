# tab completion for imeta
# TODO verify spaces are handled correctly
# TODO document
# TODO if using argparse is successfuly, convert all other completions to using
#      it.
# TODO remove any unused functions/__irods_*.

# TODO In a future version, have tab completions suggest wildcards where
#      appropriate.

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

function __imeta_count_unitless_coll_attr_val --argument-names coll attr val
  set absColl (__irods_absolute_path $coll)
  __irods_quest '%s' \
    "select count(META_COLL_ATTR_UNITS)
     where COLL_NAME = '$absColl'
       and META_COLL_ATTR_NAME = '$attr'
       and META_COLL_ATTR_VALUE = '$val'
       and META_COLL_ATTR_UNITS = ''"
end

function __imeta_count_unitless_data_attr_val --argument-names data attr val
  set pathParts (__irods_split_path (__irods_absolute_path $data))
  __irods_quest '%s' \
    "select count(META_DATA_ATTR_UNITS)
     where COLL_NAME = '$pathParts[1]'
       and DATA_NAME = '$pathParts[2]'
       and META_DATA_ATTR_NAME = '$attr'
       and META_DATA_ATTR_VALUE = '$val'
       and META_DATA_ATTR_UNITS = ''"
end

function __imeta_count_unitless_resc_attr_val --argument-names resc attr val
  __irods_quest '%s' \
    "select count(META_RESC_ATTR_UNITS)
     where RESC_NAME = '$resc'
       and META_RESC_ATTR_NAME = '$attr'
       and META_RESC_ATTR_VALUE = '$val'
       and META_RESC_ATTR_UNITS = ''"
end

function __imeta_count_unitless_user_attr_val --argument-names user attr val
  __irods_quest '%s' \
    "select count(META_USER_ATTR_UNITS)
     where USER_NAME = '$user'
       and META_USER_ATTR_NAME = '$attr'
       and META_USER_ATTR_VALUE = '$val'
       and META_USER_ATTR_UNITS = ''"
end

function __imeta_eval_with_cmdline
  set cmdline (__imeta_cmdline_args)
  eval (string escape $argv "$cmdline")
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

function __imeta_parse_for --argument-names optSpec exclusive consumer cmdline
  set optSpecArray (string split -- ' ' $optSpec)
  set cmdTokens (__imeta_tokenize_cmdline $optSpecArray -- (string split -- ' ' $cmdline))
  set _curr_token $cmdTokens[-1]
  set --erase cmdTokens[-1]
  if test -n "$exclusive"
    set exclusiveOpt '--exclusive' $exclusive
  end
  argparse --stop-nonopt $exclusiveOpt --name imeta $optSpecArray -- $cmdTokens 2>&1 | read failMsg
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
  __imeta_parse_for "$optSpec" '' $consumer $cmdline
end

function __imeta_parse_cmd_args_for --argument-names consumer cmdline
  function opts
    fish_opt --short C
    fish_opt --short d
    fish_opt --short R
    fish_opt --short u
  end
  set optSpec (opts)
  __imeta_parse_for "$optSpec" C,d,R,u $consumer $cmdline
end

function __imeta_parse_cp_args_for --argument-names consumer cmdline
  function opts
    fish_opt --short C
    fish_opt --short d
    fish_opt --short R
    fish_opt --short u
  end
  set cmdTokens (__imeta_tokenize_cmdline (opts) -- (string split -- ' ' $cmdline))
  set _curr_token $cmdTokens[-1]
  set --erase cmdTokens[-1]
  if test (count $cmdTokens) -ge 1
    switch $cmdTokens[1]
      case -C
        set _flag_C 1
      case -d
        set _flag_d 1
      case -R
        set _flag_R 1
      case -u
        set _flag_u 1
      case '*'
        set unknown_flag $cmdTokens[1]
    end
    if not set --query unknown_flag
      set --erase cmdTokens[1]
      if test (count $cmdTokens) -ge 1
        switch $cmdTokens[1]
          case -C
            set _flag_C $_flag_C 2
          case -d
            set _flag_d $_flag_d 2
          case -R
            set _flag_R $_flag_R 2
          case -u
            set _flag_u $_flag_u 2
          case '*'
            set unknown_flag $cmdTokens[1]
        end
        if not set --query unknown_flag
          set --erase cmdTokens[1]
        end
      end
    end
  end
  set _unparsed_args $cmdTokens
  eval "$consumer"
end

function __imeta_parse_ls_args_for --argument-names consumer cmdline
  set cmdTokens (string split -- ' ' $cmdline)
  set _curr_token $cmdTokens[-1]
  set --erase cmdTokens[-1]
  if test (count $cmdTokens) -ge 1
    switch $cmdTokens[1]
      case -C
        set _flag_C -C
      case -d
        set _flag_d -d
      case -ld
        set _flag_d -ld
      case -R
        set _flag_R -R
      case -u
        set _flag_u -u
      case '*'
        set unknown_flag $cmdTokens[1]
    end
    if not set --query unknown_flag
      set --erase cmdTokens[1]
    end
  end
  set _unparsed_args $cmdTokens
  eval "$consumer"
end

function __imeta_parse_any_cmd_for --argument-names consumer cmdline
  function condition --no-scope-shadowing --argument-names consumer
    if test (count $_unparsed_args) -eq 0
      false
    else
      set cmd $_unparsed_args[1]
      set _unparsed_args $_unparsed_args $_curr_token
      set --erase _unparsed_args[1]
      switch $cmd
        case cp
          __imeta_parse_cp_args_for $consumer "$_unparsed_args"
        case ls
          __imeta_parse_ls_args_for $consumer "$_unparsed_args"
        case lsw
          __imeta_parse_ls_args_for $consumer "$_unparsed_args"
        case '*'
          __imeta_parse_cmd_args_for $consumer "$_unparsed_args"
      end
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
      switch $cmd
        case cp
          __imeta_parse_cp_args_for $consumer "$_unparsed_args"
        case ls
          __imeta_parse_ls_args_for $consumer "$_unparsed_args"
        case lsw
          __imeta_parse_ls_args_for $consumer "$_unparsed_args"
        case '*'
          __imeta_parse_cmd_args_for $consumer "$_unparsed_args"
      end
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
  and __imeta_am_admin
end

# main conditions

function __imeta_no_cmd_or_help_cond --argument-names cmdline
  function condition --no-scope-shadowing
    test (count $_unparsed_args) -eq 0
    and not set --query _flag_h
  end
  __imeta_parse_main_for condition $cmdline
end

function __imeta_help_needs_cmd --argument-names cmdline
  function condition --no-scope-shadowing
    test (count $_unparsed_args) -eq 1 -a "$_unparsed_args[1]" = help
    and not set --query _flag_h
    and not set --query _flag_V
    and not set --query _flag_v
    and not set --query _flag_z
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

function __imeta_cp_src_flag_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_no_cmd_args cp $cmdline
end

function __imeta_cp_admin_src_flag_cond --argument-names cmdline
  __imeta_cp_src_flag_cond $cmdline
  and __imeta_am_admin
end

function __imeta_cp_coll_dest_flag_cond --argument-names cmdline
  function condition --no-scope-shadowing
    test (count $_flag_C) -eq 1 -a (count $_unparsed_args) -eq 0
    and not set --query _flag_d
    and not set --query _flag_R
    and not set --query _flag_u
  end
  __imeta_parse_cmd_for condition cp $cmdline
end

function __imeta_cp_admin_coll_dest_flag_cond --argument-names cmdline
  __imeta_cp_coll_dest_flag_cond $cmdline
  and __imeta_am_admin
end

function __imeta_cp_src_coll_cond --argument-names cmdline
  function condition --no-scope-shadowing
    if test "$_flag_C[1]" = 1 -a (count $_unparsed_args) -eq 0
      test (count $_flag_C) -eq 2
      or set --query _flag_d
      or set --query _flag_R
      or set --query _flag_u
    else
      false
    end
  end
  __imeta_parse_cmd_for condition cp $cmdline
end

function __imeta_cp_data_dest_flag_cond --argument-names cmdline
  function condition --no-scope-shadowing
    test (count $_flag_d) -eq 1 -a (count $_unparsed_args) -eq 0
    and not set --query _flag_C
    and not set --query _flag_R
    and not set --query _flag_u
  end
  __imeta_parse_cmd_for condition cp $cmdline
end

function __imeta_cp_admin_data_dest_flag_cond --argument-names cmdline
  __imeta_cp_data_dest_flag_cond $cmdline
  and __imeta_am_admin
end

function __imeta_cp_src_data_cond --argument-names cmdline
  function condition --no-scope-shadowing
    if test "$_flag_d[1]" = 1 -a (count $_unparsed_args) -eq 0
      test (count $_flag_d) -eq 2
      or set --query _flag_C
      or set --query _flag_R
      or set --query _flag_u
    else
      false
    end
  end
  __imeta_parse_cmd_for condition cp $cmdline
end

function __imeta_cp_resc_dest_flag_cond --argument-names cmdline
  function condition --no-scope-shadowing
    test (count $_flag_R) -eq 1 -a (count $_unparsed_args) -eq 0
    and not set --query _flag_C
    and not set --query _flag_d
    and not set --query _flag_u
  end
  __imeta_parse_cmd_for condition cp $cmdline
end

function __imeta_cp_src_resc_cond --argument-names cmdline
  function condition --no-scope-shadowing
    if test "$_flag_R[1]" = 1 -a (count $_unparsed_args) -eq 0
      test (count $_flag_R) -eq 2
      or set --query _flag_C
      or set --query _flag_d
      or set --query _flag_u
    else
      false
    end
  end
  __imeta_parse_cmd_for condition cp $cmdline
end

function __imeta_cp_user_dest_flag_cond --argument-names cmdline
  function condition --no-scope-shadowing
    test (count $_flag_u) -eq 1 -a (count $_unparsed_args) -eq 0
    and not set --query _flag_C
    and not set --query _flag_d
    and not set --query _flag_R
  end
  __imeta_parse_cmd_for condition cp $cmdline
end

function __imeta_cp_src_user_cond --argument-names cmdline
  function condition --no-scope-shadowing
    if test "$_flag_u[1]" = 1 -a (count $_unparsed_args) -eq 0
      test (count $_flag_u) -eq 2
      or set --query _flag_C
      or set --query _flag_d
      or set --query _flag_R
    else
      false
    end
  end
  __imeta_parse_cmd_for condition cp $cmdline
end

function __imeta_cp_to_coll_cond --argument-names cmdline
  function condition --no-scope-shadowing
    test "$_flag_C[-1]" = 2 -a (count $_unparsed_args) -eq 1
  end
  __imeta_parse_cmd_for condition cp $cmdline
end

function __imeta_cp_to_data_cond --argument-names cmdline
  function condition --no-scope-shadowing
    test "$_flag_d[-1]" = 2 -a (count $_unparsed_args) -eq 1
  end
  __imeta_parse_cmd_for condition cp $cmdline
end

function __imeta_cp_to_resc_cond --argument-names cmdline
  function condition --no-scope-shadowing
    test "$_flag_R[-1]" = 2 -a (count $_unparsed_args) -eq 1
  end
  __imeta_parse_cmd_for condition cp $cmdline
end

function __imeta_cp_to_user_cond --argument-names cmdline
  function condition --no-scope-shadowing
    test "$_flag_u[-1]" = 2 -a (count $_unparsed_args) -eq 1
  end
  __imeta_parse_cmd_for condition cp $cmdline
end

# ls conditions

function __imeta_ls_flag_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_no_cmd_args ls $cmdline
end

function __imeta_ls_coll_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_coll ls $cmdline
end

function __imeta_ls_coll_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_C 1' ls $cmdline
end

function __imeta_ls_data_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_data ls $cmdline
end

function __imeta_ls_data_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_d 1' ls $cmdline
end

function __imeta_ls_resc_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_resc ls $cmdline
end

function __imeta_ls_resc_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_R 1' ls $cmdline
end

function __imeta_ls_user_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_user ls $cmdline
end

function __imeta_ls_user_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_u 1' ls $cmdline
end

# lsw conditions

function __imeta_lsw_flag_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_no_cmd_args lsw $cmdline
end

function __imeta_lsw_coll_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_coll lsw $cmdline
end

function __imeta_lsw_data_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_data lsw $cmdline
end

function __imeta_lsw_resc_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_resc lsw $cmdline
end

function __imeta_lsw_user_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_user lsw $cmdline
end

# mod conditions

function __imeta_mod_new_cond --argument-names flag termLbl cmdline
  function condition --no-scope-shadowing --argument-names flag termLbl
    set argCnt (count $_unparsed_args)
    if not set --query $flag
       or test "$argCnt" -lt 3 -o "$argCnt" -gt 6
       or string match --invert --quiet --regex '^'$termLbl'?$' $_curr_token
      false
    else if test "$argCnt" -eq 3
      switch $flag
        case _flag_C
          test (__imeta_count_unitless_coll_attr_val $_unparsed_args) -ge 1
        case _flag_d
          test (__imeta_count_unitless_data_attr_val $_unparsed_args) -ge 1
        case _flag_R
          test (__imeta_count_unitless_resc_attr_val $_unparsed_args) -ge 1
        case _flag_u
          test (__imeta_count_unitless_user_attr_val $_unparsed_args) -ge 1
        case '*'
          false
      end
    else
      for arg in $_unparsed_args
        if string match --quiet --regex '^'$termLbl: $arg
          return 1
        end
      end
      true
    end
  end
  __imeta_parse_cmd_for "condition $flag $termLbl" mod $cmdline
end

function __imeta_mod_flag_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_no_cmd_args mod $cmdline
end

function __imeta_mod_admin_flag_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_no_cmd_args mod $cmdline
  and __imeta_am_admin
end

function __imeta_mod_coll_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_coll mod $cmdline
end

function __imeta_mod_coll_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_C 1' mod $cmdline
end

function __imeta_mod_coll_attr_val_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_C 2' mod $cmdline
end

function __imeta_mod_coll_avu_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_C 3' mod $cmdline
end

function __imeta_mod_coll_new_attr_cond --argument-names cmdline
  __imeta_mod_new_cond _flag_C n $cmdline
end

function __imeta_mod_coll_new_val_cond --argument-names cmdline
  __imeta_mod_new_cond _flag_C v $cmdline
end

function __imeta_mod_coll_new_unit_cond --argument-names cmdline
  __imeta_mod_new_cond _flag_C u $cmdline
end

function __imeta_mod_data_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_data mod $cmdline
end

function __imeta_mod_data_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_d 1' mod $cmdline
end

function __imeta_mod_data_attr_val_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_d 2' mod $cmdline
end

function __imeta_mod_data_avu_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_d 3' mod $cmdline
end

function __imeta_mod_data_new_attr_cond --argument-names cmdline
  __imeta_mod_new_cond _flag_d n $cmdline
end

function __imeta_mod_data_new_val_cond --argument-names cmdline
  __imeta_mod_new_cond _flag_d v $cmdline
end

function __imeta_mod_data_new_unit_cond --argument-names cmdline
  __imeta_mod_new_cond _flag_d u $cmdline
end

function __imeta_mod_resc_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_resc mod $cmdline
end

function __imeta_mod_resc_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_R 1' mod $cmdline
end

function __imeta_mod_resc_attr_val_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_R 2' mod $cmdline
end

function __imeta_mod_resc_avu_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_R 3' mod $cmdline
end

function __imeta_mod_resc_new_attr_cond --argument-names cmdline
  __imeta_mod_new_cond _flag_R n $cmdline
end

function __imeta_mod_resc_new_val_cond --argument-names cmdline
  __imeta_mod_new_cond _flag_R v $cmdline
end

function __imeta_mod_resc_new_unit_cond --argument-names cmdline
  __imeta_mod_new_cond _flag_R u $cmdline
end

function __imeta_mod_user_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_user mod $cmdline
end

function __imeta_mod_user_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_u 1' mod $cmdline
end

function __imeta_mod_user_attr_val_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_u 2' mod $cmdline
end

function __imeta_mod_user_avu_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_u 3' mod $cmdline
end

function __imeta_mod_user_new_attr_cond --argument-names cmdline
  __imeta_mod_new_cond _flag_u n $cmdline
end

function __imeta_mod_user_new_val_cond --argument-names cmdline
  __imeta_mod_new_cond _flag_u v $cmdline
end

function __imeta_mod_user_new_unit_cond --argument-names cmdline
  __imeta_mod_new_cond _flag_u u $cmdline
end

# qu conditions

function __imeta_qu_flag_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_no_cmd_args qu $cmdline
end

function __imeta_qu_op_cond --argument-names cmdline
  function condition --no-scope-shadowing
    if set --query _flag_C
       or set --query _flag_d
      test (math (count $_unparsed_args) \% 4) -eq 1
    else
      test (count $_unparsed_args) -eq 1
    end
  end
  __imeta_parse_cmd_for condition qu $cmdline
end

function __imeta_qu_and_cond --argument-names cmdline
  function condition --no-scope-shadowing
    if set --query _flag_C
       or set --query _flag_d
      test (math (count $_unparsed_args) \% 4) -eq 3
    else
      false
    end
  end
  __imeta_parse_cmd_for condition qu $cmdline
end

# rm conditions

function __imeta_rm_flag_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_no_cmd_args rm $cmdline
end

function __imeta_rm_admin_flag_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_no_cmd_args rm $cmdline
  and __imeta_am_admin
end

function __imeta_rm_coll_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_coll rm $cmdline
end

function __imeta_rm_coll_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_C 1' rm $cmdline
end

function __imeta_rm_coll_attr_val_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_C 2' rm $cmdline
end

function __imeta_rm_coll_avu_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_C 3' rm $cmdline
end

function __imeta_rm_data_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_data rm $cmdline
end

function __imeta_rm_data_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_d 1' rm $cmdline
end

function __imeta_rm_data_attr_val_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_d 2' rm $cmdline
end

function __imeta_rm_data_avu_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_d 3' rm $cmdline
end

function __imeta_rm_resc_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_resc rm $cmdline
end

function __imeta_rm_resc_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_R 1' rm $cmdline
end

function __imeta_rm_resc_attr_val_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_R 2' rm $cmdline
end

function __imeta_rm_resc_avu_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_R 3' rm $cmdline
end

function __imeta_rm_user_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_user rm $cmdline
end

function __imeta_rm_user_attr_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_u 1' rm $cmdline
end

function __imeta_rm_user_attr_val_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_u 2' rm $cmdline
end

function __imeta_rm_user_avu_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_u 3' rm $cmdline
end

# rmi conditions

function __imeta_rmi_flag_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_no_cmd_args rmi $cmdline
end

function __imeta_rmi_admin_flag_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_no_cmd_args rmi $cmdline
  and __imeta_am_admin
end

function __imeta_rmi_coll_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_coll rmi $cmdline
end

function __imeta_rmi_coll_meta_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_C 1' rmi $cmdline
end

function __imeta_rmi_data_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_data rmi $cmdline
end

function __imeta_rmi_data_meta_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_d 1' rmi $cmdline
end

function __imeta_rmi_resc_cond --argument-names cmdline
  __imeta_parse_cmd_for __imeta_cmd_needs_resc rmi $cmdline
end

function __imeta_rmi_resc_meta_cond --argument-names cmdline
  __imeta_parse_cmd_for '__imeta_cmd_has_flag_with_num_args _flag_R 1' rmi $cmdline
end


#
# Suggestion functions
#

# XXX strip trailing / off collection suggestions. A bug in iRODS 4.1.10
#     prevents imeta from finding the collection when it ends in /. See
#     https://github.com/irods/irods/issues/4559. This is still present in
#     iRODS 4.2.6.
function __imeta_coll_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set ignored ''
    if test (count $_flag_C) -eq 2 -a (count $_unparsed_args) -eq 1
      set ignored $_unparsed_args[1]
    end
    __irods_collection_suggestions $_curr_token \
      | string trim --right --chars / \
      | string match --all --invert $ignored
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_coll_meta_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set coll $_unparsed_args[1]
    set absColl (__irods_absolute_path $coll)
    __irods_quest '%s' "select META_COLL_ATTR_ID where COLL_NAME = '$absColl'"
  end
__imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_any_coll_attr_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attrPat $_curr_token%
    __irods_quest '%s' "select META_COLL_ATTR_NAME where META_COLL_ATTR_NAME like '$attrPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_given_coll_attr_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set coll $_unparsed_args[1]
    set attrPat $_curr_token%
    set absColl (__irods_absolute_path $coll)
    __irods_quest '%s' \
      "select META_COLL_ATTR_NAME
       where COLL_NAME = '$absColl' and META_COLL_ATTR_NAME like '$attrPat'"
  end
__imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_any_coll_attr_val_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set valPat $_curr_token%
    __irods_quest '%s' \
      "select META_COLL_ATTR_VALUE
       where META_COLL_ATTR_NAME = '$attr' and META_COLL_ATTR_VALUE like '$valPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_given_coll_attr_val_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set coll $_unparsed_args[1]
    set attr $_unparsed_args[2]
    set valPat $_curr_token%
    set absColl (__irods_absolute_path $coll)
    __irods_quest '%s' \
      "select META_COLL_ATTR_VALUE
       where COLL_NAME = '$absColl'
         and META_COLL_ATTR_NAME = '$attr'
         and META_COLL_ATTR_VALUE like '$valPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_any_coll_attr_val_unit_args --argument-names cmdline
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

function __imeta_given_coll_attr_val_unit_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set coll $_unparsed_args[1]
    set attr $_unparsed_args[2]
    set val $_unparsed_args[3]
    set unitPat $_curr_token%
    set absColl (__irods_absolute_path $coll)
    __irods_quest '%s' \
      "select META_COLL_ATTR_UNITS
       where COLL_NAME = '$absColl'
         and META_COLL_ATTR_NAME = '$attr'
         and META_COLL_ATTR_VALUE = '$val'
         and META_COLL_ATTR_UNITS like '$unitPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_data_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set ignored ''
    if test (count $_flag_d) -eq 2 -a (count $_unparsed_args) -eq 1
      set ignored $_unparsed_args[1]
    end
    __irods_path_suggestions $_curr_token | string match --all --invert $ignored
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_data_meta_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set data $_unparsed_args[1]
    set pathParts (__irods_split_path (__irods_absolute_path $data))
    __irods_quest '%s' \
      "select META_DATA_ATTR_ID where COLL_NAME = '$pathParts[1]' and DATA_NAME = '$pathParts[2]'"
  end
__imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_any_data_attr_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attrPat $_curr_token%
    __irods_quest '%s' "select META_DATA_ATTR_NAME where META_DATA_ATTR_NAME like '$attrPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_given_data_attr_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set data $_unparsed_args[1]
    set attrPat $_curr_token%
    set pathParts (__irods_split_path (__irods_absolute_path $data))
    __irods_quest '%s' \
      "select META_DATA_ATTR_NAME
       where COLL_NAME = '$pathParts[1]'
         and DATA_NAME = '$pathParts[2]'
         and META_DATA_ATTR_NAME like '$attrPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_any_data_attr_val_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set valPat $_curr_token%
    __irods_quest '%s' \
      "select META_DATA_ATTR_VALUE
       where META_DATA_ATTR_NAME = '$attr' and META_DATA_ATTR_VALUE like '$valPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_given_data_attr_val_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set data $_unparsed_args[1]
    set attr $_unparsed_args[2]
    set valPat $_curr_token%
    set pathParts (__irods_split_path (__irods_absolute_path $data))
    __irods_quest '%s' \
      "select META_DATA_ATTR_VALUE
       where COLL_NAME = '$pathParts[1]'
         and DATA_NAME = '$pathParts[2]'
         and META_DATA_ATTR_NAME = '$attr'
         and META_DATA_ATTR_VALUE like '$valPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_any_data_attr_val_unit_args --argument-names cmdline
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

function __imeta_given_data_attr_val_unit_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set data $_unparsed_args[1]
    set attr $_unparsed_args[2]
    set val $_unparsed_args[3]
    set unitPat $_curr_token%
    set pathParts (__irods_split_path (__irods_absolute_path $data))
    __irods_quest '%s' \
      "select META_DATA_ATTR_UNITS
       where COLL_NAME = '$pathParts[1]'
         and DATA_NAME = '$pathParts[2]'
         and META_DATA_ATTR_NAME = '$attr'
         and META_DATA_ATTR_VALUE = '$val'
         and META_DATA_ATTR_UNITS like '$unitPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_resc_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set ignored ''
    if test (count $_flag_R) -eq 2 -a (count $_unparsed_args) -eq 1
      set ignored $_unparsed_args[1]
    end
    __irods_quest '%s' "select RESC_NAME where RESC_NAME != '$ignored'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_resc_meta_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set resc $_unparsed_args[1]
    __irods_quest '%s' "select META_RESC_ATTR_ID where RESC_NAME = '$resc'"
  end
__imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_any_resc_attr_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attrPat $_curr_token%
    __irods_quest '%s' "select META_RESC_ATTR_NAME where META_RESC_ATTR_NAME like '$attrPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_given_resc_attr_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set resc $_unparsed_args[1]
    set attrPat $_curr_token%
    __irods_quest '%s' \
      "select META_RESC_ATTR_NAME where RESC_NAME = '$resc' and META_RESC_ATTR_NAME like '$attrPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_any_resc_attr_val_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set valPat $_curr_token%
    __irods_quest '%s' \
      "select META_RESC_ATTR_VALUE
       where META_RESC_ATTR_NAME = '$attr' and META_RESC_ATTR_VALUE like '$valPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_given_resc_attr_val_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set resc $_unparsed_args[1]
    set attr $_unparsed_args[2]
    set valPat $_curr_token%
    __irods_quest '%s' \
      "select META_RESC_ATTR_VALUE
       where RESC_NAME = '$resc'
         and META_RESC_ATTR_NAME = '$attr'
         and META_RESC_ATTR_VALUE like '$valPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_any_resc_attr_val_unit_args --argument-names cmdline
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

function __imeta_given_resc_attr_val_unit_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set resc $_unparsed_args[1]
    set attr $_unparsed_args[2]
    set val $_unparsed_args[3]
    set unitPat $_curr_token%
    __irods_quest '%s' \
      "select META_RESC_ATTR_UNITS
       where RESC_NAME = '$resc'
         and META_RESC_ATTR_NAME = '$attr'
         and META_RESC_ATTR_VALUE = '$val'
         and META_RESC_ATTR_UNITS like '$unitPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_user_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set ignored ''
    if test (count $_flag_u) -eq 2 -a (count $_unparsed_args) -eq 1
      set ignored $_unparsed_args[1]
    end
    __irods_quest '%s' "select USER_NAME where USER_NAME != '$ignored'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_any_user_attr_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attrPat $_curr_token%
    __irods_quest '%s' "select META_USER_ATTR_NAME where META_USER_ATTR_NAME like '$attrPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_given_user_attr_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set user $_unparsed_args[1]
    set attrPat $_curr_token%
    __irods_quest '%s' \
      "select META_USER_ATTR_NAME where USER_NAME = '$user' and META_USER_ATTR_NAME like '$attrPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_any_user_attr_val_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set attr $_unparsed_args[2]
    set valPat $_curr_token%
    __irods_quest '%s' \
      "select META_USER_ATTR_VALUE
       where META_USER_ATTR_NAME = '$attr' and META_USER_ATTR_VALUE like '$valPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_given_user_attr_val_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set user $_unparsed_args[1]
    set attr $_unparsed_args[2]
    set valPat $_curr_token%
    __irods_quest '%s' \
      "select META_USER_ATTR_VALUE
       where USER_NAME = '$user'
         and META_USER_ATTR_NAME = '$attr'
         and META_USER_ATTR_VALUE like '$valPat'"
  end
  __imeta_parse_any_cmd_for suggestions $cmdline
end

function __imeta_any_user_attr_val_unit_args --argument-names cmdline
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

function __imeta_given_user_attr_val_unit_args --argument-names cmdline
  function suggestions --no-scope-shadowing
    set user $_unparsed_args[1]
    set attr $_unparsed_args[2]
    set val $_unparsed_args[3]
    set unitPat $_curr_token%
    __irods_quest '%s' \
      "select META_USER_ATTR_UNITS
       where USER_NAME = '$user'
         and META_USER_ATTR_NAME = '$attr'
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

function __imeta_mk_cmd_completion --argument-names cmd description condition
  complete --command imeta --arguments $cmd \
    --condition '__imeta_eval_with_cmdline __imeta_help_needs_cmd' \
    --description $description
  complete --command imeta --arguments $cmd \
    --condition "__imeta_eval_with_cmdline $condition" \
    --description $description
end

# Having an argument completion for a flag, makes completions suggest a flag
# even when the current token is "", i.e., when no hyphen is present. Having
# an argument completion instead of a short option completion results in the
# suggestions being unordered, so both completions are needed.
function __imeta_mk_flag_completions --argument-names opt description condition
  complete --command imeta --arguments "-$opt" \
    --condition "__imeta_eval_with_cmdline $condition" \
    --description $description
  complete --command imeta --short-option $opt \
    --condition "__imeta_eval_with_cmdline $condition" \
    --description $description
end


complete --command imeta --no-files

complete --command imeta --arguments help \
  --condition '__imeta_eval_with_cmdline __imeta_no_cmd_or_help_cond' \
  --description 'shows help'
complete --command imeta --arguments upper \
  --condition '__imeta_eval_with_cmdline __imeta_help_needs_cmd' \
  --description 'toggle between upper case mode for queries'

__imeta_mk_flag_completions h 'shows help' __imeta_no_cmd_or_help_cond

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

__imeta_mk_cmd_completion add 'add new AVU triple' __imeta_no_cmd_or_help_cond

# add -C
__imeta_mk_flag_completions C 'to collection' __imeta_add_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_coll_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_add_coll_cond'

# add -d
__imeta_mk_flag_completions d 'to data object' __imeta_add_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_data_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_add_data_cond'

# add -R
__imeta_mk_flag_completions R 'to resource' '__irods_exec_slow __imeta_add_admin_flag_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_resc_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_add_resc_cond'

# add -u
__imeta_mk_flag_completions u 'to user' '__irods_exec_slow __imeta_add_admin_flag_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_user_args)' \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_add_user_cond'

# adda

__imeta_mk_cmd_completion adda 'administratively add new AVU triple' \
  '__irods_exec_slow __imeta_adda_cond'

# adda -C
__imeta_mk_flag_completions C 'to collection' __imeta_adda_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_coll_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_coll_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_any_coll_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_coll_attr_cond' \
  --description 'existing for collections'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_any_coll_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_coll_attr_val_cond' \
  --description 'existing for attribute'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_any_coll_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_coll_avu_cond' \
  --description 'existing for attribute-value'

# adda -d
__imeta_mk_flag_completions d 'to data object' __imeta_adda_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_data_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_data_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_any_data_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_data_attr_cond' \
  --description 'existing for data objects'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_any_data_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_data_attr_val_cond' \
  --description 'existing for attribute'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_any_data_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_data_avu_cond' \
  --description 'existing for attribute-value'

# adda -R
__imeta_mk_flag_completions R 'to resource' __imeta_adda_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_resc_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_resc_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_any_resc_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_resc_attr_cond' \
  --description 'existing for resources'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_any_resc_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_resc_attr_val_cond' \
  --description 'existing for attribute'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_any_resc_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_resc_avu_cond' \
  --description 'existing for attribute-value'

# adda -u
__imeta_mk_flag_completions u 'to user' __imeta_adda_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_user_args)' \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_adda_user_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_any_user_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_user_attr_cond' \
  --description 'existing for users'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_any_user_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_user_attr_val_cond' \
  --description 'existing for attribute'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_any_user_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_adda_user_avu_cond' \
  --description 'existing for attribute-value'

# addw

__imeta_mk_cmd_completion addw 'add new AVU triple using wildcards in name' \
  __imeta_no_cmd_or_help_cond
__imeta_mk_flag_completions d 'to data object' __imeta_addw_flag_cond

# cp

__imeta_mk_cmd_completion cp 'copy AVUs from one item to another' __imeta_no_cmd_or_help_cond

# cp (-C|-d|-R|-u)
__imeta_mk_flag_completions C 'from collection' __imeta_cp_src_flag_cond
__imeta_mk_flag_completions d 'from data object' __imeta_cp_src_flag_cond
__imeta_mk_flag_completions R 'from resource' '__irods_exec_slow __imeta_cp_admin_src_flag_cond'
__imeta_mk_flag_completions u 'from user' '__irods_exec_slow __imeta_cp_admin_src_flag_cond'

# cp -C (-C|-d|-R|-u)
__imeta_mk_flag_completions C 'to collection' __imeta_cp_coll_dest_flag_cond
__imeta_mk_flag_completions d 'to data object' __imeta_cp_coll_dest_flag_cond
__imeta_mk_flag_completions R 'to resource' '__irods_exec_slow __imeta_cp_admin_coll_dest_flag_cond'
__imeta_mk_flag_completions u 'to user' '__irods_exec_slow __imeta_cp_admin_coll_dest_flag_cond'

# cp -d (-C|-d|-R|-u)
__imeta_mk_flag_completions C 'to collection' __imeta_cp_data_dest_flag_cond
__imeta_mk_flag_completions d 'to data object' __imeta_cp_data_dest_flag_cond
__imeta_mk_flag_completions R 'to resource' '__irods_exec_slow __imeta_cp_admin_data_dest_flag_cond'
__imeta_mk_flag_completions u 'to user' '__irods_exec_slow __imeta_cp_admin_data_dest_flag_cond'

# cp -R (-C|-d|-R|-u)
__imeta_mk_flag_completions C 'to collection' __imeta_cp_resc_dest_flag_cond
__imeta_mk_flag_completions d 'to data object' __imeta_cp_resc_dest_flag_cond
__imeta_mk_flag_completions R 'to resource' __imeta_cp_resc_dest_flag_cond
__imeta_mk_flag_completions u 'to user' __imeta_cp_resc_dest_flag_cond

# cp -u (-C|-d|-R|-u)
__imeta_mk_flag_completions C 'to collection' __imeta_cp_user_dest_flag_cond
__imeta_mk_flag_completions d 'to data object' __imeta_cp_user_dest_flag_cond
__imeta_mk_flag_completions R 'to resource' __imeta_cp_user_dest_flag_cond
__imeta_mk_flag_completions u 'to user' __imeta_cp_user_dest_flag_cond

# cp (-C|-d|-R|-u) (-C|-d|-R|-u) <from-entity>
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_coll_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_cp_src_coll_cond' \
  --description 'source collection'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_data_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_cp_src_data_cond' \
  --description 'source data object'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_resc_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_cp_src_resc_cond' \
  --description 'source resource'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_user_args)' \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_cp_src_user_cond' \
  --description 'source resource'

# cp (-C|-d|-R|-u) (-C|-d|-R|-u) <from-entity> <to-entity>
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_coll_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_cp_to_coll_cond' \
  --description 'destination collection'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_data_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_cp_to_data_cond' \
  --description 'destination data object'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_resc_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_cp_to_resc_cond' \
  --description 'destination resource'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_user_args)' \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_cp_to_user_cond' \
  --description 'destination user'

# ls

__imeta_mk_cmd_completion ls 'list existing AVUs' __imeta_no_cmd_or_help_cond

# ls -C
__imeta_mk_flag_completions C 'of collection' __imeta_ls_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_coll_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_ls_coll_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_coll_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_ls_coll_attr_cond'

# ls -[l]d
__imeta_mk_flag_completions d 'of data object' __imeta_ls_flag_cond
complete --command imeta --arguments '-ld' \
  --condition '__imeta_eval_with_cmdline __imeta_ls_flag_cond' \
  --description 'of data object, show set time'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_data_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_ls_data_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_data_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_ls_data_attr_cond'

# ls -R
__imeta_mk_flag_completions R 'of resource' __imeta_ls_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_resc_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_ls_resc_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_resc_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_ls_resc_attr_cond'

# ls -u
__imeta_mk_flag_completions u 'of user' __imeta_ls_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_user_args)' \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_ls_user_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_user_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_ls_user_attr_cond'

# lsw

__imeta_mk_cmd_completion lsw 'list existing AVUs using wildcards' __imeta_no_cmd_or_help_cond

# lsw -C
__imeta_mk_flag_completions C 'of collection' __imeta_lsw_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_coll_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_lsw_coll_cond'

# lsw -[l]d
__imeta_mk_flag_completions d 'of data object' __imeta_lsw_flag_cond
complete --command imeta --arguments '-ld' \
  --condition '__imeta_eval_with_cmdline __imeta_lsw_flag_cond' \
  --description 'of data object, show set time'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_data_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_lsw_data_cond'

# lsw -R
__imeta_mk_flag_completions R 'of resource' __imeta_lsw_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_resc_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_lsw_resc_cond'

# lsw -u
__imeta_mk_flag_completions u 'of user' __imeta_lsw_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_user_args)' \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_lsw_user_cond'

# mod

__imeta_mk_cmd_completion mod 'modify AVU' __imeta_no_cmd_or_help_cond

# mod -C
__imeta_mk_flag_completions C 'of collection' __imeta_mod_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_coll_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_coll_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_coll_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_coll_attr_cond' \
  --description 'current attribute'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_coll_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_coll_attr_val_cond' \
  --description 'current value'
complete --command imeta \
  --arguments \
    '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_coll_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_coll_avu_cond' \
  --description 'current unit'
complete --command imeta --arguments n: \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_mod_coll_new_attr_cond' \
  --description 'new attribute'
complete --command imeta --arguments v: \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_mod_coll_new_val_cond' \
  --description 'new value'
complete --command imeta --arguments u: \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_mod_coll_new_unit_cond' \
  --description 'new unit'

# mod -d
__imeta_mk_flag_completions d 'of data object' __imeta_mod_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_data_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_data_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_data_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_data_attr_cond' \
  --description 'current attribute'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_data_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_data_attr_val_cond' \
  --description 'current value'
complete --command imeta \
  --arguments \
    '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_data_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_data_avu_cond' \
  --description 'current unit'
complete --command imeta --arguments n: \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_mod_data_new_attr_cond' \
  --description 'new attribute'
complete --command imeta --arguments v: \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_mod_data_new_val_cond' \
  --description 'new value'
complete --command imeta --arguments u: \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_mod_data_new_unit_cond' \
  --description 'new unit'

# mod -R
__imeta_mk_flag_completions R 'of resource' '__irods_exec_slow __imeta_mod_admin_flag_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_resc_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_resc_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_resc_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_resc_attr_cond' \
  --description 'current attribute'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_resc_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_resc_attr_val_cond' \
  --description 'current value'
complete --command imeta \
  --arguments \
    '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_resc_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_resc_avu_cond' \
  --description 'current unit'
complete --command imeta --arguments n: \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_mod_resc_new_attr_cond' \
  --description 'new attribute'
complete --command imeta --arguments v: \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_mod_resc_new_val_cond' \
  --description 'new value'
complete --command imeta --arguments u: \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_mod_resc_new_unit_cond' \
  --description 'new unit'

# mod -u
__imeta_mk_flag_completions u 'of user' '__irods_exec_slow __imeta_mod_admin_flag_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_user_args)' \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_mod_user_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_user_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_user_attr_cond' \
  --description 'current attribute'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_user_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_user_attr_val_cond' \
  --description 'current value'
complete --command imeta \
  --arguments \
    '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_user_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_mod_user_avu_cond' \
  --description 'current unit'
complete --command imeta --arguments n: \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_mod_user_new_attr_cond' \
  --description 'new attribute'
complete --command imeta --arguments v: \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_mod_user_new_val_cond' \
  --description 'new value'
complete --command imeta --arguments u: \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_mod_user_new_unit_cond' \
  --description 'new unit'

# qu

__imeta_mk_cmd_completion qu 'query entities with matching AVUs' __imeta_no_cmd_or_help_cond
__imeta_mk_flag_completions C collections __imeta_qu_flag_cond
__imeta_mk_flag_completions d 'data objects' __imeta_qu_flag_cond
__imeta_mk_flag_completions R resources __imeta_qu_flag_cond
__imeta_mk_flag_completions u users __imeta_qu_flag_cond

# qu operators
complete --command imeta --arguments = \
  --condition '__imeta_eval_with_cmdline __imeta_qu_op_cond' \
  --description 'equals lexicographically'
complete --command imeta --arguments '\<\>' \
  --condition '__imeta_eval_with_cmdline __imeta_qu_op_cond' \
  --description 'doesn\'t equal lexicographically'
complete --command imeta --arguments '\<' \
  --condition '__imeta_eval_with_cmdline __imeta_qu_op_cond' \
  --description 'less than lexicographically'
complete --command imeta --arguments '\<=' \
  --condition '__imeta_eval_with_cmdline __imeta_qu_op_cond' \
  --description 'less than or equals lexicographically'
complete --command imeta --arguments '\>=' \
  --condition '__imeta_eval_with_cmdline __imeta_qu_op_cond' \
  --description 'greater than or equals lexicographically'
complete --command imeta --arguments '\>' \
  --condition '__imeta_eval_with_cmdline __imeta_qu_op_cond' \
  --description 'greater than lexicographically'
complete --command imeta --arguments like \
  --condition '__imeta_eval_with_cmdline __imeta_qu_op_cond' \
  --description 'matches wildcard'
complete --command imeta --arguments 'not\ like' \
  --condition '__imeta_eval_with_cmdline __imeta_qu_op_cond' \
  --description 'doesn\'t match wildcard'
complete --command imeta --arguments n= \
  --condition '__imeta_eval_with_cmdline __imeta_qu_op_cond' \
  --description 'equals numerically'
complete --command imeta --arguments 'n\<\>' \
  --condition '__imeta_eval_with_cmdline __imeta_qu_op_cond' \
  --description 'doesn\'t equal numerically'
complete --command imeta --arguments 'n\<' \
  --condition '__imeta_eval_with_cmdline __imeta_qu_op_cond' \
  --description 'less than numerically'
complete --command imeta --arguments 'n\<=' \
  --condition '__imeta_eval_with_cmdline __imeta_qu_op_cond' \
  --description 'less than or equals numerically'
complete --command imeta --arguments 'n\>=' \
  --condition '__imeta_eval_with_cmdline __imeta_qu_op_cond' \
  --description 'greater than or equals numerically'
complete --command imeta --arguments 'n\>' \
  --condition '__imeta_eval_with_cmdline __imeta_qu_op_cond' \
  --description 'greater than numerically'

# qu joins
# TODO imeta qu (-C|-d) <attr> <op> <val> or ...
# TODO imeta qu (-C|-d) <attr> <op> <val> or <op> <val> ... and ...
# Waiting for https://github.com/irods/irods/issues/4458 to be fixed.
complete --command imeta --arguments and \
  --condition '__imeta_eval_with_cmdline __imeta_qu_and_cond' \
  --description 'intersect with condition on other attribute'

# rm

__imeta_mk_cmd_completion rm 'remove AVU' __imeta_no_cmd_or_help_cond

# rm -C
__imeta_mk_flag_completions C 'of collection' __imeta_rm_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_coll_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_coll_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_coll_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_coll_attr_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_coll_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_coll_attr_val_cond'
complete --command imeta \
  --arguments \
    '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_coll_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_coll_avu_cond'

# rm -d
__imeta_mk_flag_completions d 'of data object' __imeta_rm_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_data_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_data_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_data_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_data_attr_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_data_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_data_attr_val_cond'
complete --command imeta \
  --arguments \
    '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_data_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_data_avu_cond'

# rm -R
__imeta_mk_flag_completions R 'of resource' '__irods_exec_slow __imeta_rm_admin_flag_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_resc_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_resc_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_resc_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_resc_attr_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_resc_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_resc_attr_val_cond'
complete --command imeta \
  --arguments \
    '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_resc_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_resc_avu_cond'

# rm -u
__imeta_mk_flag_completions u 'of user' '__irods_exec_slow __imeta_rm_admin_flag_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_user_args)' \
  --condition '__imeta_eval_with_cmdline __irods_exec_slow __imeta_rm_user_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_user_attr_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_user_attr_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_user_attr_val_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_user_attr_val_cond'
complete --command imeta \
  --arguments \
    '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_given_user_attr_val_unit_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rm_user_avu_cond'

# rmi

__imeta_mk_cmd_completion rmi 'remove AVU by metadata id' __imeta_no_cmd_or_help_cond

# rmi -C
__imeta_mk_flag_completions C 'of collection' __imeta_rmi_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_coll_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rmi_coll_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_coll_meta_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rmi_coll_meta_cond'

# rmi -d
__imeta_mk_flag_completions d 'of data object' __imeta_rmi_flag_cond
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_data_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rmi_data_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_data_meta_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rmi_data_meta_cond'

# rmi -R
__imeta_mk_flag_completions R 'of resource' '__irods_exec_slow __imeta_rmi_admin_flag_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_resc_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rmi_resc_cond'
complete --command imeta \
  --arguments '(__imeta_eval_with_cmdline __irods_exec_slow __imeta_resc_meta_args)' \
  --condition '__imeta_eval_with_cmdline __imeta_rmi_resc_meta_cond'

# TODO imeta rmi -u <user> <metadata-id>

# rmw

__imeta_mk_cmd_completion rmw 'remove AVU using wildcards' __imeta_no_cmd_or_help_cond
# TODO imeta rmw (-C|-d|-R|-u) <entity> <attr> <val> [<units>]

# set

__imeta_mk_cmd_completion set 'assign a single value' __imeta_no_cmd_or_help_cond
# TODO imeta set (-C|-d|-R|-u) <entity> <attr> <new-val> [<new-units>]


functions --erase __imeta_mk_flag_completions __imeta_mk_cmd_completion
