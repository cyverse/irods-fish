# tab completion for imeta
#
# TODO determine allowed order or arguments
# TODO extend to cover options
# TODO make suggest appropriate arguments
# TODO make suggest multiple arguments, if applicable
# TODO wrap all of this in a function that generates the completions, then call the function

#
# Helper Functions
#

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

# TODO consider interpreting all tokens instead of stopping at first unknown.
#      This will catch -z after occurring after a command and still be able
#      to suggest a zone.
function __imeta_suggest --argument-names condition
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


#
# Condition functions
#

function __imeta_suggest_cmd
  function condition --no-scope-shadowing
    if set --query _flag_h
      false
    else
      test (count $_unparsed_args) -eq 0
    end
  end
  __imeta_suggest condition
end

function __imeta_suggest_verbose
  function condition --no-scope-shadowing
    test (count $_unparsed_args) -eq 0
    and not set --query _flag_h
    and not set --query _flag_V
    and not set --query _flag_v
  end
  __imeta_suggest condition
end

function __imeta_suggest_zone
  function condition --no-scope-shadowing
    if set --query _flag_z
      test -z $_flag_z
    else
      test (count $_unparsed_args) -eq 0
      and not set --query _flag_h
    end
  end
  __imeta_suggest condition
end


#
# Suggestion functions
#

function __imeta_zone_suggestions
  iquest --no-page -- '%s' 'select ZONE_NAME' | string match --invert 'CAT_NO_ROWS_FOUND:*'
end


#
# Completions
#

complete --command imeta --no-files

# TODO make help be suggested always
__irods_help_completion imeta

# imeta -V
complete --command imeta --short-option V --condition __imeta_suggest_verbose \
  --description 'very verbose'

# imeta -v
complete --command imeta --short-option v --condition __imeta_suggest_verbose \
  --description verbose

# imeta -z <zone>
# XXX imeta -(v|V)z doesn't make any suggestions. This is a bug in fish. See
#     https://github.com/fish-shell/fish-shell/issues/5127. Check to see if this
#     is still a problem after upgrading to fish 3.1+.
complete --command imeta --short-option z \
  --arguments '(__irods_exec_slow __imeta_zone_suggestions)' --exclusive \
  --condition __imeta_suggest_zone \
  --description 'work with the specified zone'

# imeta add
complete --command imeta --arguments add --no-files --condition __imeta_suggest_cmd \
  --description 'add new AVU triple'

# TODO imeta add (-d|-C|-R|-u) <entity> <attribute> <value> [<unit>]
#complete --command imeta --arguments '(__irods_exec_slow __irods_path_suggestions)' --no-files

# imeta adda
complete --command imeta --arguments adda --condition __imeta_suggest_cmd \
  --description 'administratively add new AVU triple'

# TODO imeta adda (-d|-C|-R|-u) <entity> <attribute> <value> [<units>]

# imeta addw
complete --command imeta --arguments addw --condition __imeta_suggest_cmd \
  --description 'add new AVU triple using wildcards in name'

# TODO imeta addw (-d|-C|-R|-u) <entity> <attribute> <value> [<units>]

# imeta cp
complete --command imeta --arguments cp --condition __imeta_suggest_cmd \
  --description 'copy AVUs from one item to another'

# TODO imeta cp (-d|-C|-R|-u) (-d|-C|-R|-u) <from-entity> <to-entity>

# imeta ls
complete --command imeta --arguments ls --condition __imeta_suggest_cmd \
  --description 'list existing AVUs'

# TODO imeta ls (-d|-C|-R|-u) <entity> [<attribute>]

# imeta lsw
complete --command imeta --arguments lsw --condition __imeta_suggest_cmd \
  --description 'list existing AVUs using wildcards'

# TODO imeta lsw (-d|-C|-R|-u) <entity> [<attribute>]

# imeta mod
complete --command imeta --arguments mod --condition __imeta_suggest_cmd \
  --description 'modify AVU'

# TODO imeta mod (-d|-C|-R|-u) <entity> <attribute> <value> [<unit>][n:<new-attribute>][v:<new-value>][u:<new-units>]

# imeta qu
complete --command imeta --arguments qu --condition __imeta_suggest_cmd \
  --description 'query entities with matching AVUs'

# TODO imeta qu (-d|-C|-R|-u) <attribute> <op> <value> ...

# imeta set
complete --command imeta --arguments set --condition __imeta_suggest_cmd \
  --description 'assign a single value'

# TODO imeta set (-d|-C|-R|-u) <entity> <attribute> <new-value> [<new-units>]

# imeta rm
complete --command imeta --arguments rm --condition __imeta_suggest_cmd \
  --description 'remove AVU'

# imeta rmi
complete --command imeta --arguments rmi --condition __imeta_suggest_cmd \
  --description 'remove AVU by metadata id'

# TODO imeta rmi (-d|-C|-R|-u) <entity> <metadata-id>

# TODO imeta rm (-d|-C|-R|-u) <entity> <attribute> <value> [<units>]

# imeta rmw
complete --command imeta --arguments rmw --condition __imeta_suggest_cmd \
  --description 'remove AVU using wildcards'

# TODO imeta rmw (-d|-C|-R|-u) <entity> <attribute> <value> [<units>]
