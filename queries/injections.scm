; Comments may hold TODO, FIXME, … markers.
((comment) @injection.content
  (#set! injection.language "comment"))

; LilyPond code in a Scheme string:
;   #(ly:parser-include-string "\\include \"file.ly\"")
((scheme_list
  .
  (scheme_symbol) @_function
  .
  (scheme_string
    (string_content) @injection.content))
  (#any-of? @_function
    "ly:parser-include-string" "ly:parse-string-expression"
    "ly:parse-init")
  (#set! injection.language "lilypond"))
