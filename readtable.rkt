#lang racket

(provide elmlisp-readtable)

; TODO read [] {} #[] differently
; https://github.com/takikawa/racket-clojure/blob/master/clojure/reader.rkt#L28-L36

; readtable allowing us to read stuff differently (atm color, but hopefully [] {} #[])
(define (elmlisp-readtable)
  (make-readtable (current-readtable)
                  
                  ; treat , as whitespace
                  #\,
                  'terminating-macro
                  read-as-whitespace

                  ; treat < as , in the current readtable (unquote?)
                  #\<
                  #\,
                  (current-readtable)))

(define (read-as-whitespace . a)
  (make-special-comment #f))