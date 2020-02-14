# TODO document
# irods_env_color
# irods_cwd_color

function irods_prompt \
    --description ''

  function read_ienv --argument-names var
    for line in (command ienv)
      if string match --quiet --regex "$var" $line
        if set val (string replace --regex -- '^.*'"$var"' - ' '' $line)
          echo $val
          return 0
        end
        return 1
      end
    end
    return 1
  end

  function fmt_icwd
    set --query irods_cwd_color
    or set irods_cwd_color $fish_cwd_color
    set home (read_ienv irods_home)
    or set home /(read_ienv irods_zone_name)/home/(read_ienv irods_user_name)
    set cwd (string replace --regex '^'"$home"'($|/)' '~$1' (command ipwd))
    set cwd (string replace --all --regex '(\.?[^/]{1})[^/]*/' '$1/' $cwd)
    printf '%s%s%s' (set_color $irods_cwd_color) $cwd (set_color normal)
  end

  function fmt_ienv
    set --query irods_env_color
    or set irods_env_color normal
    set env (basename --suffix .json $IRODS_ENVIRONMENT_FILE)
    printf '%s%s%s' (set_color $irods_env_color) $env (set_color normal)
  end

  if set --query IRODS_ENVIRONMENT_FILE
    printf '%s %s' (fmt_ienv) (fmt_icwd)
  end

  printf '? '
end

