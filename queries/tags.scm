; Tags for code navigation.
;
; The tags library only accepts the captures @name, @doc, @definition.*,
; @reference.* and @local.*, so the keywords that predicates test are
; captured as @local.reference, which it ignores here.

; Music functions and other functions defined in LilyPond:
;   transposeUp = #(define-music-function (music) (ly:music?) …)
(assignment
  name: (identifier) @name
  value: (embedded_scheme
    value: (scheme_list
      .
      (scheme_symbol) @local.reference
      (#any-of? @local.reference
        "define-music-function" "define-event-function"
        "define-scheme-function" "define-void-function")))) @definition.function

; Top-level variables: melody = \relative { … }
(_
  (assignment
    name: (identifier) @name
    value: [
      (sequential_music)
      (simultaneous_music)
      (function_call)
      (contexted_music)
      (command)
      (note)
      (chord)
      (repeat)
      (lyric_mode)
      (chord_mode)
      (figure_mode)
      (drum_mode)
      (note_mode)
      (markup)
      (markuplist)
      (embedded_lilypond)
      (score_block)
      (book_block)
      (bookpart_block)
      (header_block)
      (paper_block)
      (layout_block)
      (midi_block)
      (with_block)
      (context_definition)
    ]) @definition.constant)

; Scheme functions: #(define (name …) …)
(scheme_list
  .
  (scheme_symbol) @local.reference
  .
  (scheme_list
    .
    (scheme_symbol) @name)
  (#any-of? @local.reference "define" "define-public" "define*" "define*-public")) @definition.function

; Markup commands: #(define-markup-command (name layout props …) …)
(scheme_list
  .
  (scheme_symbol) @local.reference
  .
  (scheme_list
    .
    (scheme_symbol) @name)
  (#any-of? @local.reference "define-markup-command" "define-markup-list-command")) @definition.function

; Function calls in the input: \transposeUp, \relative, …
(function_call
  name: (command) @name) @reference.call
