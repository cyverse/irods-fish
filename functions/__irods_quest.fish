# This function performs an iquest with an empty result returning nothing 
# instead of an error message. The first argument, fmt, formats the result rows
# using iquest syntax. The second argument, query, is the iquest formatted query
# to perform.

function __irods_quest --argument-names fmt query \
    --description 'perform an iquest where an empty result returns nothing'

  command iquest --no-page -- $fmt $query | string match --invert 'CAT_NO_ROWS_FOUND:*'
end
