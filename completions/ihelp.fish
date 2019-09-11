# tab completions for ihelp

#
# Helper Functions
#

function __ihelp_parse_arg --argument-names arg
  if string match --invert --quiet --regex -- '^-.+' $arg  # - or iCommand
    echo $arg
  else                                                     # short arg group
    # split apart short arg group
    set argChars (string split -- '' (string trim --left --chars '-' -- $arg))
    while [ (count $argChars) -gt 0 ]
      if string match --quiet --regex -- '[ah]' $argChars[1]  # flag
        echo '-'$argChars[1]
        set --erase argChars[1]
      else                                                    # unknown
        # Dump the rest as part of an unknown argument
        string join -- '' '-' $argChars
        break
      end
    end
    return 0
  end
end

# This function tokenizes the current arguments passed to ihelp. It would expand
# all of the options to individual arguments, e.g., '-ah' would become '-a'
# '-h'. If the cursor is still on an argument, i.e., the character before the
# cursor isn't white space, the last argument returned would be the current
# argument. Otherwise, it would be a space, i.e., ' '.
function __ihelp_parse_args
  set completeArgs (commandline --cut-at-cursor --tokenize)
  set --erase completeArgs[1]
  set remainingArg (commandline --cut-at-cursor --current-token)
  set args $completeArgs $remainingArg
  for arg in $completeArgs $remainingArg
    __ihelp_parse_arg $arg
  end
end


#
# Condition Functions
#

function __ihelp_no_args
  set args (__ihelp_parse_args)
  switch (count $args)
    case 0
      return 0
    case 1
      test $args[1] = -
    case '*'
      return 1
  end
end


#
# Suggestion Functions
#

function __ihelp_suggestions
  if [ (count (commandline --cut-at-cursor --tokenize)) -eq 1 ]
    set args \
      iadmin ibun icd ichksum ichmod icp idbug ienv ierror iexecmd iexit ifsck iget igetwild \
      igroupadmin ihelp iinit ilocate ils ilsresc imcoll imeta imiscsvrinfo imkdir imv ipasswd \
      iphybun iphymv ips iput ipwd iqdel iqmod iqstat iquest iquota ireg irepl irm irmtrash irsync \
      irule iscan isysmeta iticket itrim iuserinfo ixmsg izonereport
    for arg in $args
      echo $arg
    end
  end
end


#
# Completions
#

complete --command ihelp --short-option h \
  --description 'shows help' \
  --condition '__ihelp_no_args' --exclusive

complete --command ihelp --short-option a \
  --description 'prints the help text for all the iCommands' \
  --condition '__ihelp_no_args' --exclusive

# TODO should not match if -h or -a are present
# TODO see how git add is implemented
complete --command ihelp --arguments '(__ihelp_suggestions)' --no-files
