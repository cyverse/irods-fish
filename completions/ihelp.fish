# tab completions for ihelp

function __ihelp_argument_suggestions \
    --description 'Generates the argument suggestions for ihelp'
  set cmd (commandline --cut-at-cursor --tokenize)
  if [ (count $cmd) -eq 1 ]
    set args \
      iadmin ibun icd ichksum ichmod icp idbug ienv ierror iexecmd iexit ifsck iget igetwild \
      igroupadmin ihelp iinit ilocate ils ilsresc imcoll imeta imiscsvrinfo imkdir imv ipasswd \
      iphybun iphymv ips iput ipwd iqdel iqmod iqstat iquest iquota ireg irepl irm irmtrash irsync \
      irule iscan isysmeta iticket itrim iuserinfo ixmsg izonereport
    for arg in $args
      printf '%s\n' $arg
    end
  end
end

complete --command ihelp --short-option h \
  --description 'shows help' \
  --exclusive

complete --command ihelp --short-option a \
  --description 'prints the help text for all the iCommands' \
  --exclusive

complete --command ihelp \
  --no-files --arguments '(__ihelp_argument_suggestions)'
