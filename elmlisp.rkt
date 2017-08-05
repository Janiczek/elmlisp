#lang racket

; TODO do we need defmacro?
(require compatibility/defmacro)

(define arg-out-filename (make-parameter "ElmLisp"))
(define arg-filenames
  (command-line
   #:args filenames
   filenames))

; TODO read [] {} #[] differently
; https://github.com/takikawa/racket-clojure/blob/master/clojure/reader.rkt#L28-L36

(define (read-as-whitespace a)
  (make-special-comment #f))

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


(define code (void))

; TODO temporary crutch - when ready, put back the stdin/file behaviour
; https://bitbucket.org/ktg/l/src/57a5293aa0f040c81afd799364f3aaacaf8676fa/l++.rkt?at=master&fileviewer=file-view-default#l%2B%2B.rkt-26:31
(set! code (file->string "elm-examples/all-syntax.ell"))

; wrap it all into one list
(set! code (string-append "(" code ")"))

; parse the string into Racket forms (with a few exceptions given by the readtable)
(define parsed
  (parameterize ([current-readtable (elmlisp-readtable)])
    (read (open-input-string code))))

; Racket-y macro magic.
(define-namespace-anchor anc)
(define ns (namespace-anchor->namespace anc))
(define (macroexpand-1 lst)
  (syntax->datum (expand-to-top-form (eval `(syntax ,lst) ns))))
(define macros (mutable-set))

; (foo bar baz) => foo, bar, baz
; (..) => ..
; (foo) => foo
; ((Msg (..)) => Msg(..)
(define (format-exposing list)
  (string-join (map (lambda exposed
                      (if (and (list? exposed)
                               (equal? (second exposed)
                                       '(..)))
                        (format "~a(..)" (first exposed))
                        ~a))
                        
                    list)
               ", "))

; String            => String
; (Html Msg)        => Html Msg
; (Html (List Int)) => Html (List Int)
(define (format-type type)
  (if (list? type)
      (string-join (map ~a type) " ")
      (~a type)))

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
                 
                 [(defmacro) ; discouraged, non-hygienic.
                             ; also, we remapped unquote from , to <
                             ; so that we can claim , as whitespace
                  (set-add! macros (second e))
                  (eval e ns)
                  ""]

                 ; (module Foo exposing (main view)) => module Foo exposing (main, view)
                 ; (module Nested.Bar exposing (..)) => module Nested.Bar exposing (..)
                 ; TODO:
                 ; (module Baz exposing ((Msg (..))) => module Baz exposing (Msg(..))
                 [(module)
                  (format "module ~a exposing (~a)"
                          (second e)
                          (format-exposing (fourth e)))]

                 ; (import Foo)
                 ; =>
                 ; import Foo

                 ; (import Foo as F)
                 ; =>
                 ; import Foo as F

                 ; (import Foo exposing (bar baz))
                 ; =>
                 ; import Foo exposing (bar, baz)

                 ; (import Foo as F exposing (..))
                 ; =>
                 ; import Foo as F exposing (..)
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

                 ; (type-alias Model Int)
                 ; =>
                 ; type alias Model = Int

                 ; (type-alias User { name String, age Int }
                 ; =>
                 ; type alias User = { name : String, age : Int }

                 ; (type-alias MyHtml (Html Int))
                 ; =>
                 ; type alias MyHtml = Html Int

                 ; (type-alias MyCmd (Cmd (List String)))
                 ; =>
                 ; type alias MyCmd = Cmd (List String)

                 ; (type-alias (Param a) (Html (List a)))
                 ; =>
                 ; type alias Param a = Html (List a)
                 [(type-alias)
                  (format "type alias ~a = ~a"
                          (format-type (second e))
                          (format-type (third e)))]

                 ; (type Bool True False)
                 ; =>
                 ; type Bool = True | False

                 ; (type 
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


(define compiled
  (~a (string-join
       (map compile-expr parsed)
       "\n"
       #:after-last "\n")))

; TODO when ready, delete this
(displayln compiled)

(define outsrc
  (~a (arg-out-filename) ".elm"))

(define outbin
  (arg-out-filename))

(define out
  (open-output-file
    outsrc
    #:exists 'replace))

; write the result to a file
; (displayln compiled out) ; TODO when ready, uncomment this
(close-output-port out)
