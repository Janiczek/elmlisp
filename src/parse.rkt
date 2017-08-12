#lang racket

(provide parse)

; Let Racket reader do the heavy lifting (String -> S-exprs).
; We change it up a bit with our modified readtable...
(define (parse code)
  (parameterize ([current-readtable (elmlisp-readtable)]
                 [read-accept-bar-quote #f])
    (read (open-input-string code))))

; readtable allowing us to read stuff differently (colon, [], {}, #[])
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
                  read-elm-tuple
                  
                  ; treat {} as (elm-record)
                  #\{
                  'terminating-macro
                  read-elm-record))

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
    #`(elm-list #,@list)
    list-syntax
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
    #`(elm-tuple #,@list)
    list-syntax
    list-syntax))

(define/contract (elm-record-syntax list-syntax list)
                 (-> any/c
                     (flat-named-contract 'even-sized-list (compose even? length))
                     syntax?)
 (datum->syntax
   list-syntax
   #`(elm-record #,@(sequence->list (in-slice 2 list)))
   list-syntax
   list-syntax))

; {abc def ...} -> (elm-record (abc def) ...)
(define (read-elm-record ch in src ln col pos)
  (define list-syntax
    (parameterize ([read-accept-dot #f])
                  (read-syntax/recursive src in ch
                                         (make-readtable
                                           (current-readtable)
                                           ch #\{ #f))))
  (define list (syntax->list list-syntax))
  (elm-record-syntax list-syntax list))
