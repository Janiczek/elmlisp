#lang racket

(provide wrap-in-parens
         format-compiled-code
         indent
         format-exposing
         format-type
         format-module
         format-type-definition
         format-arguments
         format-cases
         format-record-pair-value)

(require threading
         (only-in srfi/13 string-null?)
         "helpers.rkt")

; when reading a file, wrap all its s-exprs into one list
(define (wrap-in-parens string)
 (format "(~a)" string))

; combine all Elm source code strings to one
(define (format-compiled-code list)
  (~a (string-join
        list
        "\n\n"
        #:after-last "\n")))

(define (indent string)
  (string-join
    (for/list ([line (in-lines (open-input-string string))])
      (if (string-null? line)
        line
        (format "    ~a" line)))
    "\n"))

; used for "exposing (foo bar)"
;                    ^^^^^^^^^
; ------------------------------
; (foo bar baz) => foo, bar, baz
; (..)          => ..
; (foo)         => foo
; ((Msg (..)))  => Msg(..)
(define (format-exposing list)
  (string-join
    (map (lambda (exposed)
           (if (is-exposed-adt? exposed)
               (format-exposed-adt exposed)
               (~a exposed)))       
         list)
    ", "))

(define (format-exposed-adt adt)
  (match adt
         [`(,name ,constructors)
          (format "~a(~a)"
                  name
                  (string-join (map ~a constructors) ", "))]))
           

; used for all kinds of type annotations
; basically remove outermost parens but otherwise leave as is
; with exception of (->)
; --------------------------------
; String             => String
; (Html Msg)         => Html Msg
; (Html (List a))    => Html (List a)
; (-> Int String)    => Int -> String
; (-> Int (List a))  => Int -> List a
; (-> (-> a b) a b)  => (a -> b) -> a -> b
; (elm-record a Int) => { a : Int }
(define (format-type type #:nested? [nested? #f])
  (cond
    [(is-record? type)
     (format-record-type type)]
     
    [(is-arrow-type? type)
     (if nested?
       (wrap-in-parens (format-arrow-type type))
       (format-arrow-type type))]

    [(list? type)
     (string-join (map ~a type) " ")]

    [else
      (~a type)]))

(define (format-record-type type)
  (case (length type)
    [(0) "{}"]
    [else (format "{ ~a }"
                  (string-join (map (compose format-record-pair-type
                                             format-record-pair-rhs)
                                (rest type)) 
                               " , "))]))

(define/match (format-record-pair-rhs pair)
  [(`(,field ,type)) `(,field ,(format-type type))])

(define (format-arrow-type type)
  (string-join (map (lambda (type-part)
                      (format-type type-part #:nested? #t))
                    (rest type))
               " -> "))

; allows module, port module
(define (format-module expr module-type)
  (match expr
         [`(,_ ,name)
           (format "~a ~a exposing (..)"
                   module-type
                   name)]
         [`(,_ ,name exposing ,exposed)
           (format "~a ~a exposing (~a)"
                   module-type
                   name
                   (format-exposing exposed))]))

; used for (type)
; ---------------
; (True False)       => True | False
; (Nothing (Just a)) => Nothing | Just a
(define (format-type-definition constructors)
  (string-join (map format-type constructors)
               "\n    | "))

; used in lambdas and defn
; -------------------
; TODO: destructuring
; -------------------
; (x y) => x y
; [x y] => x y
(define (format-arguments arguments)
  (match arguments
         [`(elm-list . ,args)
          (string-join (map ~a args) " ")]
         [`,args
           (string-join (map ~a args) " ")]))

; ((True 1) (False 0))              => True -> 1 \n False -> 0
; ((Inc 1) ((IncBy amount) amount)) => Inc -> 1 \n IncBy amount -> amount
; -----------------------
(define (format-cases cases)
  (string-join (map format-case cases) "\n\n"))

(define (format-case case)
  (match case
         [`(,constructor ,value)
          (format "    ~a ->\n        ~a"
                  (format-type constructor)
                  value)]))

(define (format-record-pair-type pair)
  (match pair
         [`(,field ,value)
          (format "~a : ~a"
                  field
                  value)]))

(define (format-record-pair-value pair)
  (match pair
         [`(,field ,value)
          (format "~a = ~a"
                  field
                  value)]))
