function __irods_exec_slow \
    --description 'Executes the given command while indicating visually to wait'

  # Add hourglass to right of cursor
  printf ' \u23f3\x08\x08\x08' >&2

  eval "$argv"

  # TODO make this a function that fires on function_exit
  # Remove hourglass
  printf '  \x08\x08' >&2
end
