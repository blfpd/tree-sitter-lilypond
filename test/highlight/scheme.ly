myFunction =
% <- variable
#(define-music-function (music) (ly:music?)
; <- punctuation.special
;^ punctuation.bracket
; ^ keyword.function
;                       ^ punctuation.bracket
;                        ^ variable.parameter
;                                ^ function.builtin
   "Documentation."
;  ^ string
   #{ \transpose c d $music #})
%  ^ punctuation.special
%     ^ function.builtin
%                    ^ punctuation.special
%                     ^ variable.parameter
%                           ^ punctuation.special

#(define (double x) ; twice x
; ^ keyword
;         ^ function
;                ^ variable.parameter
;                   ^ comment
   (* 2 x))
%   ^ function.call
%     ^ number
%       ^ variable.parameter

flag = ##t
%      ^ punctuation.special
%       ^ boolean
direction = #UP
%            ^ constant.builtin
key = #(make-thing #:color red)
%       ^ function.call
%                  ^ string.special.symbol
percent = #(list %load-path 'symbol) % a LilyPond comment
%                ^ variable
%                           ^ operator
%                            ^ string.special.symbol
%                                    ^ comment
