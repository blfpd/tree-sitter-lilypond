%% Dump the identifiers that LilyPond defines, for scripts/update-builtins.js.
%%
%% Writes one line per definition to the file named by the environment
%% variable INTROSPECT_OUTPUT (default: builtins.tsv):
%%
%%   binding <TAB> name <TAB> type        identifiers visible to the input
%%   markup  <TAB> name <TAB> signature   markup commands (M = markup,
%%                                        L = markup list, S = anything else)
%%
%% Run it with `lilypond -s scripts/introspect.ly`. Include a file such as
%% bagpipe.ly first to see what it adds.

\version "2.24.0"

#(use-modules (ice-9 format) (srfi srfi-1))

#(define (classify value)
  (cond
   ((ly:music-function? value)
    (let* ((signature (ly:music-function-signature value))
           (result (if (pair? (car signature)) (caar signature) (car signature))))
      (cond ((eq? result ly:music?) "music-function")
            ((eq? result ly:event?) "event-function")
            ((eq? result void?) "void-function")
            (else "scheme-function"))))
   ((ly:music? value)
    (let ((name (ly:music-property value 'name)))
      (cond ((eq? name 'AbsoluteDynamicEvent) "dynamic")
            ((memq name '(CrescendoEvent DecrescendoEvent)) "dynamic")
            ((memq name '(ArticulationEvent MultiMeasureArticulationEvent))
             "articulation")
            ((music-is-of-type? value 'post-event) "post-event")
            (else "music"))))
   ((or (markup-function? value) (markup-list-function? value))
    "markup-command")
   ((null? value) "other")
   ;; \major, \minor, \dorian, …: alists of steps and alterations.
   ((and (list? value)
         (every (lambda (x) (and (pair? x) (integer? (car x)))) value))
    "scale")
   ((markup? value) "markup")
   ((ly:context-mod? value) "context-mod")
   ((ly:context-def? value) "context-def")
   ((ly:output-def? value) "output-def")
   ((ly:duration? value) "duration")
   ((ly:pitch? value) "pitch")
   ((number? value) "number")
   ((string? value) "string")
   ((procedure? value) "procedure")
   (else "other")))

#(define (signature-string command)
  (string-concatenate
   (map (lambda (predicate)
          (cond ((eq? predicate markup?) "M")
                ((eq? predicate markup-list?) "L")
                (else "S")))
        (markup-command-signature command))))

#(let ((port (open-output-file
              (or (getenv "INTROSPECT_OUTPUT") "builtins.tsv"))))
  (module-for-each
   (lambda (symbol variable)
     (if (variable-bound? variable)
         (format port "binding\t~a\t~a\n"
                 symbol (classify (variable-ref variable)))))
   (current-module))
  ;; Context definitions (\Staff, \Voice, …) only exist in \layout and
  ;; \midi.
  (for-each
   (lambda (output-def)
     (for-each
      (lambda (entry)
        (if (ly:context-def? (cdr entry))
            (format port "binding\t~a\tcontext-def\n" (car entry))))
      (ly:module->alist (ly:output-def-scope output-def))))
   (list $defaultlayout $defaultmidi))
  (module-for-each
   (lambda (symbol variable)
     (if (variable-bound? variable)
         (let ((value (variable-ref variable)))
           (if (or (markup-function? value) (markup-list-function? value))
               (format port "markup\t~a\t~a\n"
                       symbol (signature-string value))))))
   (resolve-module '(lily)))
  (close-port port))
