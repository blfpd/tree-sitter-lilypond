\header {
% <- keyword
  title = \markup \bold "Title"
% ^ property
%         ^ keyword
%                 ^ function.builtin
%                       ^ string
  composer = \markup { \fontsize #-2 \italic Me \myMarkup }
%                      ^ function.builtin
%                                ^ punctuation.special
%                                 ^ number
%                                    ^ function.builtin
%                                            ^ string
%                                               ^ function
}

\markup \column {
%       ^ function.builtin
  \line { a \musicglyph #"scripts.segno" }
% ^ function.builtin
%         ^ string
%           ^ function.builtin
%                        ^ string
  \fromproperty #'header:title
% ^ function.builtin
%                ^ operator
%                 ^ string.special.symbol
}
