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

function __imeta_suggest_cmd
  set opts \
    (fish_opt --short h) (fish_opt --short V) (fish_opt --short v) (fish_opt --short z --required)
  set argv (commandline --cut-at-cursor --tokenize)
  set --erase argv[1]
  if not argparse --stop-nonopt --name=imeta $opts -- $argv 2> /dev/null
    false
  else if set --query _flag_h
    false
  else
    test (count $argv) -eq 0
  end
end

function __imeta_suggest_zone
  set opts \
    (fish_opt --short h) (fish_opt --short V) (fish_opt --short v) (fish_opt --short z --required)
  set argv (commandline --cut-at-cursor --tokenize)
  set --erase argv[1]
  if set failMsg (argparse --stop-nonopt --name=imeta $opts -- $argv 2>&1)
    not set --query _flag_h
    and not set --query _flag_z
  else
    string match --quiet --regex '^imeta: Expected argument for option -z' $failMsg
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

# TODO consider converting to using something like __imeta_suggest_cmd
__irods_help_completion imeta

# TODO consider converting to using something like __imeta_suggest_cmd
__irods_verbose_completion imeta '__imeta_tokenize_cmdline | __irods_missing -h -V -v add adda'

# imeta -z <zone>
complete --command imeta --short-option z \
  --arguments '(__irods_exec_slow __imeta_zone_suggestions)' --exclusive \
  --condition __imeta_suggest_zone \
  --description 'work with the specified zone'

# imeta add
complete --command imeta --arguments add --no-files --condition __imeta_suggest_cmd \
  --description 'add new AVU triple'

# TODO imeta add (-d|-C|-R|-u) <entity> <attribute> <value> [<unit>]
complete --command imeta --arguments '(__irods_exec_slow __irods_path_suggestions)' --no-files

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
