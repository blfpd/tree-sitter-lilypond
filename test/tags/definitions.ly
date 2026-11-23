melody = \relative { c'4 d e f }
% <- definition.constant
%        ^ reference.call

transposeUp = #(define-music-function (music) (ly:music?) music)
% <- definition.function

#(define (double x) (* 2 x))
%         ^ definition.function
