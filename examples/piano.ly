\version "2.24.0"

upper = \relative c'' {
  \clef treble
  \time 6/8
  <<
    { \voiceOne e8( d c) b4.~ | b8 a g fis4 r8 }
    \\
    { \voiceTwo c4. g4. | e4. d4 s8 }
  >>
  \oneVoice
  \tuplet 3/2 { c'16 d e } f8-. g-. \grace { a32 b } c4.\trill |
  \acciaccatura d8 c4 r8 \ottava #1 c'4.\fermata \ottava #0 |
  \tweak color #blue c,4 <c e g\harmonic>8 c4:16 r8 |
}

lower = \relative c {
  \clef bass
  \time 6/8
  c4.\sustainOn g'\sustainOff |
  \change Staff = "upper" e'4 r8 \change Staff = "lower" g,,4 r8 |
  \set Staff.pedalSustainStyle = #'mixed
  c4.\sustainOn d\sustainOff\sustainOn | e2.\sustainOff |
  \repeat tremolo 6 { c16 g' } |
}

dynamics = {
  s2.\pp\< | s2.\mf\> | s4.\! s4.\cresc | s2.\f |
  s2.-\markup \italic "rit." |
}

\score {
  \new PianoStaff <<
    \new Staff = "upper" \upper
    \new Dynamics \dynamics
    \new Staff = "lower" \lower
  >>
  \layout {
    \context {
      \PianoStaff
      \consists "Span_arpeggio_engraver"
    }
  }
}
