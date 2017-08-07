#lang racket

; TODO: curly braces { } must create Elm records, not Racket lists
; see https://github.com/takikawa/racket-clojure/blob/master/clojure/reader.rkt#L28-L36

;   (type-alias User { name String, age Int }
; => type alias User = { name : String, age : Int }
; currently:
; => type alias User = name String age Int

; This can be done by reading {...} into (elm-record ...) and then having  case for that in (compile-expr

(require threading
         "format.rkt"
         "parse.rkt")

(provide compile)

(define (compile file-contents)
  (~>> file-contents
       (wrap-in-parens)
       (parse)
       (map compile-expr)
       (format-compiled-code)))

; ----------------------------------
; Racket-y macro magic.
(define-namespace-anchor anc)

(define ns
  (namespace-anchor->namespace anc))

(define (macroexpand-1 lst)
  (syntax->datum
   (expand-to-top-form
    (eval `(syntax ,lst) ns))))

(define macros (mutable-set))
; ----------------------------------

; This is where we emit Elm code.
(define (compile-expr e)
  (cond [(and (list? e) (not (empty? e)))
         (if (set-member? macros (first e))
             (compile-expr (macroexpand-1 e)) ; run macros first, then generate Elm code!
             (let ([f (first e)])
               (case f

                 ; Macros -- the magic sauce. I have little idea how they work internally though.
                 [(define-syntax)
                  (let ([id (second e)])
                    (when (list? id)
                      (set! id (first id)))
                    (set-add! macros id))
                  (eval e ns)
                  ""]
                 
                 [(define-syntax-rule)
                  (let ([id (first (second e))])
                    (set-add! macros id))
                  (eval e ns)
                  ""]

                 ; (module Main)                     => module Main exposing (..)
                 ; (module Foo exposing (main view)) => module Foo exposing (main, view)
                 ; (module Nested.Bar exposing (..)) => module Nested.Bar exposing (..)
                 ; (module Baz exposing ((Msg (..))) => module Baz exposing (Msg(..))
                 [(module)
                  (format-module e "module")]

                 [(port-module)
                  (format-module e "port module")]

                 ; TODO effect module

                 ; (import Foo)                      => import Foo
                 ; (import Foo as F)                 => import Foo as F
                 ; (import Foo exposing (bar baz))   => import Foo exposing (bar, baz)
                 ; (import Foo as F exposing (..))   => import Foo as F exposing (..)
                 ; (import Foo exposing ((Msg (..))) => import Foo exposing (Msg(..))
                 [(import)
                  (case (length e)
                    [(2) ; import
                     (format "import ~a" (second e))]
                    
                    [(4) ; import as / import exposing
                     (case (third e)
                       [(as)
                        (format "import ~a as ~a"
                                (second e)
                                (fourth e))]
                       
                       [(exposing)
                        (format "import ~a exposing (~a)"
                                (second e)
                                (format-exposing (fourth e)))])]
                    
                    [(6) ; import as exposing
                     (format "import ~a as ~a exposing (~a)"
                             (second e) 
                             (fourth e)
                             (format-exposing (sixth e)))])]

                 ; (type-alias Model Int)                    => type alias Model = Int
                 ; TODO: (type-alias User { name String, age Int } => type alias User = { name : String, age : Int }
                 ; (type-alias MyHtml (Html Int))            => type alias MyHtml = Html Int
                 ; (type-alias MyCmd (Cmd (List String)))    => type alias MyCmd = Cmd (List String)
                 ; (type-alias (Param a) (Html (List a)))    => type alias Param a = Html (List a)
                 [(type-alias)
                  (format "type alias ~a =\n    ~a"
                          (format-type (second e))
                          (format-type (third e)))]

                 ; (type Bool True False)            => type Bool = True | False
                 ; (type (Maybe a) Nothing (Just a)) => type Maybe a = Nothing | Just a
                 ; (type Msg Inc (DecBy Int))        => type Msg = Inc | DecBy Int
                 [(type)
                  (format "type ~a\n    = ~a"
                          (format-type (second e))
                          (format-type-definition (list-tail e 2)))]

                 ; (input-port sendToJs String) => port sendToJs : String -> Cmd msg
                 [(input-port)
                  (format "port ~a : ~a -> Cmd msg"
                          (second e)
                          (format-type (third e)))]
                 
                 ; (output-port listen Bool) => port listen : (Bool -> msg) -> Sub msg
                 [(output-port)
                  (format "port ~a : (~a -> msg) -> Sub msg"
                          (second e)
                          (format-type (third e)))]

                 ; (lambda x (+ x 1))     => \x -> x + 1
                 ; (lambda (x y) (+ x y)) => \x y -> x + y
                 [(lambda)
                  (format "\\~a -> ~a"
                          (format-arguments (second e))
                          (compile-expr (third e)))]

                 ; (def val 1)       => x = 1
                 ; (def val : Int 1) => x : Int \n x = 1
                 [(def)
                  (case (length e)
                    [(3)
                     (format "~a =\n    ~a"
                             (second e)
                             (third e))]

                    [(5)
                     (format "~a : ~a\n~a =\n    ~a"
                             (second e)
                             (format-type (fourth e))
                             (second e)
                             (compile-expr (fifth e)))])]

                 ; (if True "a" "b") => if True then "a" else "b"
                 [(if)
                  (format "if ~a then ~a else ~a"
                          (compile-expr (second e))
                          (compile-expr (third e))
                          (compile-expr (fourth e)))]

                 ; (case msg (Inc 1) ((IncBy amount) amount)) => case msg of Inc -> 1 \n IncBy amount -> amount
                 ;[(case)
                 ; (format "case ~a of\n~a"
                 ;         (compile-expr (second e))
                 ;         (format-cases))]

                 ; anything else -> show as is
                 [else ((if (string? e)
                            ~s
                            ~a)
                        e)])))]

        ; TODO maybe the deleted C++ stuff will still be useful
        ; https://bitbucket.org/ktg/l/src/57a5293aa0f040c81afd799364f3aaacaf8676fa/l++.rkt?at=master&fileviewer=file-view-default#l%2B%2B.rkt-60:122
                 
        ; anything else -> show as is
        [else ((if (string? e)
                   ~s
                   ~a)
               e)]))
