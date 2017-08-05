#lang racket

; TODO: curly braces { } must create Elm records, not Racket lists
; see https://github.com/takikawa/racket-clojure/blob/master/clojure/reader.rkt#L28-L36

;   (type-alias User { name String, age Int }
; => type alias User = { name : String, age : Int }
; currently:
; => type alias User = name String age Int

; This can be done by reading {...} into (elm-record ...) and then having  case for that in (compile)

(require "format.rkt")

(provide compile)

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
(define (compile e)
  (cond [(and (list? e) (not (empty? e)))
         (if (set-member? macros (first e))
             (compile (macroexpand-1 e)) ; run macros first, then generate Elm code!
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

                 ; (module Foo exposing (main view)) => module Foo exposing (main, view)
                 ; (module Nested.Bar exposing (..)) => module Nested.Bar exposing (..)
                 ; (module Baz exposing ((Msg (..))) => module Baz exposing (Msg(..))
                 [(module)
                  (format "module ~a exposing (~a)"
                          (second e)
                          (format-exposing (fourth e)))]

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
                 ; (type-alias User { name String, age Int } => type alias User = { name : String, age : Int }
                 ; (type-alias MyHtml (Html Int))            => type alias MyHtml = Html Int
                 ; (type-alias MyCmd (Cmd (List String)))    => type alias MyCmd = Cmd (List String)
                 ; (type-alias (Param a) (Html (List a)))    => type alias Param a = Html (List a)
                 [(type-alias)
                  (format "type alias ~a = ~a"
                          (format-type (second e))
                          (format-type (third e)))]

                 ; (type Bool True False)            => type Bool = True | False
                 ; (type (Maybe a) Nothing (Just a)) => type Maybe a = Nothing | Just a
                 ; (type Msg Inc (DecBy Int))        => type Msg = Inc | DecBy Int
                 [(type)
                  (format "type ~a = ~a"
                          (format-type (second e))
                          (third e))])))]

                 ; TODO maybe the deleted C++ stuff will still be useful
                 ; https://bitbucket.org/ktg/l/src/57a5293aa0f040c81afd799364f3aaacaf8676fa/l++.rkt?at=master&fileviewer=file-view-default#l%2B%2B.rkt-60:122
                 
        ; anything else -> show as is
        [else ((if (string? e)
                 ~s
                 ~a)
               e)]))