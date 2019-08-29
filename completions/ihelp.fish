# tab completions for ihelp

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

complete --command ihelp --short-option h \
  --description 'shows help' \
  --exclusive

complete --command ihelp --short-option a \
  --description 'prints the help text for all the iCommands' \
  --exclusive

complete --command ihelp --no-files --arguments '(__ihelp_suggestions)'
