function __irods_exec_slow \
    --description 'Executes the given command while indicating visually to wait'

  # Add hourglass to right of cursor
  printf ' \u23f3\x08\x08\x08' >&2

  eval (string escape $argv)
  set cmdStatus $status

  # Remove hourglass
  printf '  \x08\x08' >&2

  return $cmdStatus
end
