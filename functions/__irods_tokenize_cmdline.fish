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

  # Given a set of short option flags and parameters and a term, if the term is a set of short
  # options, split into multiple terms, one for each option.
  function tokenize_term --argument-names flags params term

    # If the term to tokenize isn't a short option set
    if string match --invert --quiet --regex -- '^-[^-]' $term

      # write the term to standard output on its own line
      echo $term
    else

      # split the short option set into individual characters
      set optChars (string split -- '' (string trim --left --chars '-' -- $term))

      # iterate over the characters
      while test (count $optChars) -gt 0

        # if there are flags and the the current character matches one of them
        if test -n "$flags"; and string match --quiet --regex -- "[$flags]" $optChars[1]

          # wrtie the flag to standard output on its own line
          echo -- '-'$optChars[1]

          # advance iterator
          set --erase optChars[1]

        # if there are parameters and the current character matches one of them
        else if test -n "$params"; and string match --quiet --regex -- "[$params]" $optChars[1]

          # write the parameter to standard output on its own line
          echo -- '-'$optChars[1]

          # if there are more characters
          if test (count $optChars) -gt 1

            # join them into a single string and write it to standard output on its own line
            string join -- '' $optChars[2..-1]
          end

          # advance iterator to end
          set --erase optChars

        # If the current character isn't a flag or parameter
        else

          # Combine the current character with the remaining ones into a single string; prefix it
          # with a hyphen; and write it to standard output on its own line
          string join -- '' '-' $optChars

          # advance iterator to end
          set --erase optChars
        end
      end
    end
  end

  # Retrieve completed terms on the commandline
  set completeTerms (commandline --cut-at-cursor --tokenize)

  # Removed icommand name from terms
  set --erase completeTerms[1]

  # Retrieve the current, incomplete term
  set currentTerm (commandline --cut-at-cursor --current-token)

  # Iterate over all terms
  for term in $completeTerms $currentTerm
    # Tokenize each term, writing them to standard output
    tokenize_term $shortFlags $shortOptParams $term
  end
end
