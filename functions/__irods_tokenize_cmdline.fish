# This function tokenizes the current arguments passed to a command. It expands
# all of the short options to individual arguments, e.g., "-rv" would become
# "'-r' '-v'". If the cursor is still on an argument, i.e., the character before
# the cursor isn't white space, the last argument returned would be the current
# argument. Otherwise, it would be empty, i.e., "". The command itself is
# removed.
#
# Example 1:
# The command line "ihelp -ah iad|", where "|" is the cursor, gets tokenized as
# "'-a' '-h' 'iad'".
#
# Example 2:
# The command line "ils -r --bundle -tToken /path |", where "|" is the cursor,
# gets tokenized as "'-r' '--bundle' '-t' 'Token' '/path' ''".

function __irods_tokenize_cmdline --argument-names shortFlags shortOptParams \
    --description 'Splits apart the short options into individual arguments'

  function tokenize_term --argument-names flags params term
    if string match --invert --quiet --regex -- '^-[^-]' $term
      echo $term
    else
      set optChars (string split -- '' (string trim --left --chars '-' -- $term))
      while test (count $optChars) -gt 0
        if test -n "$flags"; and string match --quiet --regex -- "[$flags]" $optChars[1]
          echo -- '-'$optChars[1]
          set --erase optChars[1]
        else if test -n "$params"; and string match --quiet --regex -- "[$params]" $optChars[1]
          echo -- '-'$optChars[1]
          if test (count $optChars) -gt 1
            string join -- '' $optChars[2..-1]
          end
          set --erase optChars
        else
          string join -- '' '-' $optChars
          set --erase optChars
        end
      end
    end
  end

  set completeTerms (commandline --cut-at-cursor --tokenize)
  set --erase completeTerms[1]
  set currentTerm (commandline --cut-at-cursor --current-token)

  for term in $completeTerms $currentTerm
    tokenize_term $shortFlags $shortOptParams $term
  end
end
