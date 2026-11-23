\version "2.24.0"

#(set-global-staff-size 18)

\paper {
  #(set-paper-size "a4")
  line-width = 180\mm - 2 * 10\mm
  ragged-last-bottom = ##f
  system-system-spacing.basic-distance = #12
}

% A music function, with LilyPond embedded in Scheme.
transposeUp =
#(define-music-function (interval music) (ly:pitch? ly:music?)
   "Transpose @var{music} up by @var{interval}."
   #{ \transpose c $interval $music #})

% A markup command.
#(define-markup-command (boxed-title layout props text) (markup?)
   "Draw @var{text} in bold, in a box."
   (interpret-markup layout props
     #{ \markup \box \bold #text #}))

redNotes = {
  \override NoteHead.color = #red
  \override Stem.color = #(rgb-color 0.8 0.1 0.1)
}

drumBeat = \drummode {
  \repeat volta 2 { bd4 hh8 hh sn4 hh8 hh | <bd cymc>4 hh sn r | }
}

\markup \column {
  \boxed-title "Functions and Scheme"
  \vspace #1
  \line { \fontsize #-2 \italic "(an example for tree-sitter-lilypond)" }
  \fill-line { \null \fromproperty #'header:title }
}

\score {
  <<
    \new Staff \with { \omit TimeSignature \remove "Bar_number_engraver" }
      \transposeUp d' { \redNotes c4 d e f | g1 }
    \new DrumStaff \drumBeat
  >>
}

\book {
  \bookpart {
    \header { title = "Part I" }
    \markuplist \column-lines { \line { A } \line { B } }
    \score { $(make-sequential-music (list #{ c'4 #} #{ d'4 #})) }
  }
}
