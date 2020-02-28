# Given a list of path segments as its arguments, this function concatenates
# them into single path. Any duplicate "/" are replaced by a single "/".

function __irods_join_path \
    --description 'combines a list of path segments into a single path'

  string match --invert -- '' $argv | string join / | string replace --all --regex '/+' /
end
