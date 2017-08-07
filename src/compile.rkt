#lang racket

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
  (if (and (list? e) (not (empty? e)))

    (if (set-member? macros (first e))
      (compile-expr (macroexpand-1 e)) ; run macros first, then generate Elm code!

      (case (first e)

        ; Macros -- the magic sauce!
        [(define-syntax)      (handle-define-syntax e)]
        [(define-syntax-rule) (handle-define-syntax-rule e)]

        ; Elm syntax
        [(module)      (compile-module e)]
        [(port-module) (compile-port-module e)]
        [(import)      (compile-import e)]
        [(type-alias)  (compile-type-alias e)]
        [(type)        (compile-type e)]
        [(input-port)  (compile-input-port e)]
        [(output-port) (compile-output-port e)]
        [(lambda)      (compile-lambda e)]
        [(def)         (compile-def e)]
        [(defn)        (compile-defn e)]
        [(if)          (compile-if e)]
        [(case)        (compile-case e)]

        [else (show-as-is e)]))

    ; TODO: maybe the deleted C++ stuff will still be useful
    ; https://bitbucket.org/ktg/l/src/57a5293aa0f040c81afd799364f3aaacaf8676fa/l++.rkt?at=master&fileviewer=file-view-default#l%2B%2B.rkt-60:122

    (show-as-is e)))

(define (show-as-is expr)
  ((if (string? expr) ~s ~a) expr))

(define (handle-define-syntax expr)
  (define (register-macro id expr)
    (set-add! macros id)
    (eval expr ns)
    "")
  (match expr
         [`(handle-define-syntax ,id ,_)
           (register-macro id expr)]

         [`(handle-define-syntax (,id ,_) ,_)
           (register-macro id expr)]))

(define (handle-define-syntax-rule expr)
  (match expr
         [`(handle-define-syntax-rule (,id ,_))
           (set-add! macros id)
           (eval expr ns)
           ""]))

(define (compile-module expr)
  (format-module expr "module"))

(define (compile-port-module expr)
  (format-module expr "port module"))

(define (compile-import expr)
  (match expr
         [`(import ,name)
           (format "import ~a"
                   name)]

         [`(import ,name as ,alias)
           (format "import ~a as ~a"
                   name
                   alias)]

         [`(import ,name exposing ,exposed)
           (format "import ~a exposing (~a)"
                   name
                   (format-exposing exposed))]

         [`(import ,name as ,alias exposing ,exposed)
           (format "import ~a as ~a exposing (~a)"
                   name
                   alias
                   (format-exposing exposed))]))

(define (compile-type-alias expr)
  (match expr
         [`(type-alias ,alias ,type)
           (format "type alias ~a =\n    ~a"
                   (format-type alias)
                   (format-type type))]))

(define (compile-type expr)
  (match expr
         [`(type ,name . ,constructors)
           (format "type ~a\n    = ~a"
                   (format-type name)
                   (format-type-definition constructors))]))

(define (compile-input-port expr)
  (match expr
         [`(input-port ,name ,type)
           (format "port ~a : (~a -> msg) -> Sub msg"
                   name
                   (format-type type))]))

(define (compile-output-port expr)
  (match expr
         [`(output-port ,name ,type)
           (format "port ~a : ~a -> Cmd msg"
                   name
                   (format-type type))]))

(define (compile-lambda expr)
  (match expr
         [`(lambda ,arguments ,body)
           (format "\\~a -> ~a"
                   (format-arguments arguments)
                   (compile-expr body))]))

(define (compile-def expr)
  (match expr
         [`(def ,name ,definition)
           (format "~a =\n    ~a"
                   name
                   definition)]

         [`(def ,name : ,type ,definition)
           (format "~a : ~a\n~a =\n    ~a"
                   name
                   (format-type type)
                   name
                   (compile-expr definition))]))

(define (compile-defn expr)
  (match expr
         [`(defn ,name ,arguments ,body)
           (format "~a ~a =\n    ~a"
                   name
                   (format-arguments arguments)
                   (compile-expr body))]

         [`(defn ,name : ,type ,arguments ,body)
           (format "~a : ~a\n~a ~a =\n    ~a"
                   name
                   (format-type type)
                   name
                   (format-arguments arguments)
                   (compile-expr body))]))

(define (compile-if expr)
  (match expr
         [`(if ,condition ,then ,else)
           (format "if ~a then ~a else ~a"
                   (compile-expr condition)
                   (compile-expr then)
                   (compile-expr else))]))

(define (compile-case expr)
  (match expr
         [`(case ,var . ,cases)
           (format "case ~a of\n~a"
                   (compile-expr var)
                   (format-cases cases))]))
