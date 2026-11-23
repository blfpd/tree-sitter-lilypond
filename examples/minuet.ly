\version "2.24.0"

\header {
  title = "Minuet in G"
  subtitle = "for tree-sitter-lilypond"
  composer = "Anonymous"
  tagline = ##f
}

global = {
  \key g \major
  \time 3/4
  \tempo "Grazioso" 4 = 112
}

melody = \relative c'' {
  \global
  \partial 4 d4\p |
  \repeat volta 2 {
    g,8( a b c d4) | e-. c-. e-. | d2\< g4\! |
    fis8( e d c b4) | a2.\fermata |
  }
  \alternative {
    { r4 r d'4 }
    { \once \override Staff.BarLine.color = #red r2. }
  }
  b4.-> c8 d4 | c8[ b a g] fis4 | g2.~ | g2 r4 \bar "|."
}

bass = \relative c {
  \global
  \clef bass
  \partial 4 r4 |
  \repeat volta 2 {
    <g b d>2. | <c e>2 r4 | b2 g4 | d'2. | d,2. |
  }
  \alternative { { R2. } { R2. } }
  g'2 fis4 | e2 d4 | g,2.~ | g2 r4 |
}

\score {
  \new PianoStaff \with { instrumentName = "Piano" } <<
    \new Staff = "upper" \melody
    \new Staff = "lower" \bass
  >>
  \layout {
    indent = 15\mm
    \context {
      \Score
      \override SpacingSpanner.base-shortest-duration = #(ly:make-moment 1/16)
    }
  }
  \midi { }
}
