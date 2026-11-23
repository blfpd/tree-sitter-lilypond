\version "2.24.0"
\language "english"

\header { title = "A Little Song" }

melody = \relative c' {
  \key f \major
  \time 4/4
  f4 g a bf | c2 a | g4. f8 g4 a | f1 |
  \repeat unfold 2 { c'8 bf a g f4 f | }
  e4( f) g( a) | f1 \bar "|."
}

verseOne = \lyricmode {
  \set stanza = "1."
  Here we sing a song, __ to -- geth -- er all a -- long,
  la la la la la, la la la la la,
  sing a -- long. __
}

verseTwo = \lyricmode {
  \set stanza = "2."
  "Now" the sun is down, _ and the stars a -- round,
  \repeat unfold 10 { _ }
  shine a -- round.
}

\score {
  <<
    \new Voice = "tune" { \melody }
    \new Lyrics \lyricsto "tune" \verseOne
    \new Lyrics \lyricsto "tune" \verseTwo
  >>
  \layout {
    \context {
      \Lyrics
      \override LyricText.font-size = #-1
    }
  }
}

% The same song, with lyrics added directly to the melody.
\score {
  \new Staff { \melody }
  \addlyrics { \verseOne }
}
