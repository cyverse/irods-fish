# This function extracts the current arguments on the command line. If the
# cursor is still on an argument, i.e., the character before the cursor isn't
# white space, the last argument returned would the term under the cursor.
# Otherwise, the last argument will be empty, i.e., "". This command itself is
# reomved.
#
# Example 1:
# For the command line "ihelp -ah iad|", where "|" is the cursor, this function
# would return ('-ah' 'iad').
#
# Exampe 2:
# For the command line "ils -r --bundle -tToken /path |", where "|" is the
# cursor, this function would return ('-r' '--bundle' '-tToken' '/path' '').

function __irods_cmdline_args
    --description "Extracts the command line arguments before cursor"

    set args (commandline --cut-at-cursor --tokenize) (commandline --cut-at-cursor --current-token)
    set --erase args[1]
    string join -- \n $args
end
