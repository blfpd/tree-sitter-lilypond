; Local scopes, definitions and references, mostly for embedded Scheme.
;
; The tree-sitter tags and highlight libraries only accept the captures
; @local.scope, @local.definition and @local.reference, so the keywords that
; predicates test are captured as references.

; Scopes

[
  (source_file)
  (book_block)
  (bookpart_block)
  (score_block)
  (embedded_lilypond)
] @local.scope

((scheme_list
  .
  (scheme_symbol) @local.reference) @local.scope
  (#any-of? @local.reference
    "define" "define*" "define-public" "define*-public" "lambda" "lambda*"
    "let" "let*" "letrec" "letrec*" "let-values" "let*-values" "do"
    "define-music-function" "define-event-function" "define-scheme-function"
    "define-void-function" "define-markup-command"
    "define-markup-list-command"))

; Definitions

; myMusic = { … }
(assignment
  name: (identifier) @local.definition)

; #(define name value)
(scheme_list
  .
  (scheme_symbol) @local.reference
  .
  (scheme_symbol) @local.definition
  (#any-of? @local.reference "define" "define-public" "define*" "define*-public"))

; #(define (name parameter …) body)
(scheme_list
  .
  (scheme_symbol) @local.reference
  .
  (scheme_list
    (scheme_symbol) @local.definition)
  (#any-of? @local.reference "define" "define-public" "define*" "define*-public"))

; (lambda (parameter …) body)
; (define-music-function (parameter …) (predicate …) body)
(scheme_list
  .
  (scheme_symbol) @local.reference
  .
  (scheme_list
    (scheme_symbol) @local.definition)
  (#any-of? @local.reference
    "lambda" "lambda*" "define-music-function" "define-event-function"
    "define-scheme-function" "define-void-function"))

; (let ((name value) …) body)
(scheme_list
  .
  (scheme_symbol) @local.reference
  .
  (scheme_list
    (scheme_list
      .
      (scheme_symbol) @local.definition))
  (#any-of? @local.reference "let" "let*" "letrec" "letrec*"))

; References

(scheme_symbol) @local.reference
