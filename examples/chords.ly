\version "2.24.0"

harmonies = \chordmode {
  c1:maj7 | a:m7 | d:m7.9 | g:7.9-/b |
  c2:6 c:6/e | f:maj7 fis:dim7 | c/g g:sus4 | c1 |
}

melody = \relative c'' {
  e1 | c2. a4 | f'4 e d c | b2 g |
  e'2 c4 g | a2 c | e4 d c b | c1 \bar "|."
}

\score {
  <<
    \new ChordNames \harmonies
    \new FretBoards \harmonies
    \new Staff \melody
    \new FiguredBass \figuremode {
      <5 3>1 <7> <7 _+> <6 4>2 <5 3>
      <6>1 <7 5-> <6 4>2 <5 3> <_>1
    }
  >>
}

% Chord names written with \chords, with markup and a repeated chord.
\chords {
  \set chordChanges = ##t
  c2 c | f:m6 q | r4 g4:aug c2_\markup { \italic "fine" }
}
