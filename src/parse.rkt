#lang racket

(provide parse)

; Let Racket reader do the heavy lifting (String -> S-exprs).
; We change it up a bit with our modified readtable...
; ----------------
; TODO: read {} #[] differently
; https://github.com/takikawa/racket-clojure/blob/master/clojure/reader.rkt#L28-L36
(define (parse code)
  (parameterize ([current-readtable (elmlisp-readtable)])
    (read (open-input-string code))))

; readtable allowing us to read stuff differently (atm color, but hopefully [] {} #[])
(define (elmlisp-readtable)
  (make-readtable (current-readtable)

                  ; treat , as whitespace
                  #\,
                  'terminating-macro
                  read-as-whitespace

                  ; treat ~ as , in the current readtable (unquote)
                  #\~
                  #\,
                  (current-readtable)
                  
                  ; treat [] as (elm-list)
                  #\[
                  'terminating-macro
                  read-elm-list
                  
                  ; treat #[] as (elm-tuple)
                  #\[
                  'dispatch-macro
                  read-elm-tuple))

; basically, ignore whatever you've been given
(define (read-as-whitespace . do-not-care)
  (make-special-comment #f))

; [abc ...] -> (elm-list abc ...)
(define (read-elm-list ch in src ln col pos)
  (define list-syntax
    (parameterize ([read-accept-dot #f])
                  (read-syntax/recursive
                    src in ch
                    (make-readtable (current-readtable)
                                    ch #\[ #f))))
  (define list (syntax->list list-syntax))
  (datum->syntax
    list-syntax
    #`(elm-list #,@list)`
    ,list-syntax
    list-syntax))


; #[abc ...] -> (elm-tuple abc ...)
(define (read-elm-tuple ch in src ln col pos)
  (define list-syntax
    (parameterize ([read-accept-dot #f])
                  (read-syntax/recursive
                    src in ch
                    (make-readtable (current-readtable)
                                    ch #\[ #f))))
  (define list (syntax->list list-syntax))
  (datum->syntax
    list-syntax
    #`(elm-tuple #,@list)`
    ,list-syntax
    list-syntax))
