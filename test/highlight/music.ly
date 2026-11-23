\version "2.24.0"
% <- keyword.directive
%        ^ string
\include "english.ly"
% <- keyword.import

melody = \relative c'' {
% <- variable
%      ^ operator
%        ^ function.builtin
%                  ^ variable
%                   ^ operator
%                      ^ punctuation.bracket
  \key g \major \time 3/4
% ^ function.builtin
%      ^ variable
%        ^ constant.builtin
%               ^ function.builtin
%                     ^ number
  g4.-> a8( b4) r8 R2.*2 s4 q |
% ^ variable
%  ^ number
%    ^ operator
%     ^ operator
%         ^ punctuation.special
%               ^ constant.builtin
%                ^ number
%                  ^ constant.builtin
%                     ^ operator
%                        ^ constant.builtin
%                           ^ constant.builtin
%                             ^ punctuation.special
  c'2\p\< <d fis>4~ d!\! e-1 \myVariable
%  ^ operator
%    ^ attribute.builtin
%      ^ attribute.builtin
%         ^ punctuation.bracket
%                 ^ punctuation.special
%                    ^ operator
%                     ^ attribute.builtin
%                         ^ operator
%                          ^ number
%                            ^ function
  \repeat volta 2 { c4 } \alternative { { d2 } }
% ^ keyword.repeat
%         ^ attribute
%               ^ number
%                        ^ keyword.repeat
  \override Staff.TimeSignature.color = #red
% ^ keyword
%           ^ type
%                 ^ type
%                               ^ property
%                                     ^ operator
%                                       ^ punctuation.special
%                                        ^ variable
  \set Staff.instrumentName = "Violin"
% ^ keyword
%            ^ property
%                             ^ string
  \omit TimeSignature \voiceOne \break
% ^ function.builtin
%       ^ type
%                     ^ constant.builtin
%                               ^ constant.builtin
  << { e4 } \\ { c4 } >> c4\rest
% ^ punctuation.bracket
%           ^ punctuation.special
%                          ^ keyword
}

\score {
% <- keyword
  \new Staff = "up" \with { instrumentName = "Fl" } \melody
% ^ keyword
%      ^ type
%                   ^ keyword
%                           ^ property
%                                                   ^ function
  \layout { indent = 15\mm \context { \Staff \consists "Ambitus_engraver" } }
% ^ keyword
%           ^ property
%                    ^ number
%                      ^ type
%                          ^ keyword
%                                     ^ type.builtin
%                                            ^ keyword
}
