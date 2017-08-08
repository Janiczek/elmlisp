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
; Racket macro magic.
(define-namespace-anchor anc)

(define ns
  (namespace-anchor->namespace anc))

(define (macroexpand-1 lst)
  (syntax->datum
    (expand-to-top-form
      (eval `(syntax ,lst) ns))))

(define macros (mutable-set))
; ----------------------------------

; Operators
(define binary-operators    (mutable-set '! '::))
(define variadic-operators  (mutable-set '&& '+ '- '* '/ '// '% '^ '++ '<< '>>)) 
(define variadic-predicates (mutable-set '== '/= '< '> '<= '>=)) 

; This is where we emit Elm code.
(define (compile-expr e)
  (cond

    ; Things that are not in (this kind of form)
    [(or (not (list? e)) (empty? e))
     (show-as-is e)]

    ; Expand macros and compile the result!
    [(set-member? macros (first e))
     (compile-expr (macroexpand-1 e))]

    ; Operators. We don't match on a fixed set of them because user can define his own / use library that defined one.
    [(set-member? binary-operators (first e))
     (compile-binary-operator e)]

    [(set-member? variadic-operators (first e))
     (compile-variadic-operator e)]

    ; Variadic predicates are joined by && 
    [(set-member? variadic-predicates (first e))
     (compile-variadic-predicate e)]

    ; Everything else is here.
    [else
      (case (first e)

        ; Macros -- the magic sauce!
        [(define-syntax
           define-syntax-rule) (handle-macro e)]

        ; Flag as operator
        [(binary-operator
           variadic-operator
           variadic-predicate) (handle-operator e)]

        ; Data structures
        [(elm-list)   (compile-list e)]
        [(elm-tuple)  (compile-tuple e)]
        [(elm-record) (compile-record e)]

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

        [else (compile-function-call e)])]))

(define (show-as-is expr)
  ((if (string? expr) ~s ~a) expr))

(define (handle-macro expr)
  (define (register-macro id expr)
    (set-add! macros id)
    (eval expr ns)
    "")
  (match expr
         [`(define-syntax ,id ,_)
           (register-macro id expr)]

         [`(define-syntax (,id ,_) ,_)
           (register-macro id expr)]

         [`(define-syntax-rule (,id ,_))
           (register-macro id expr)]))

(define (handle-operator expr)
  (for ([op (rest expr)])
       (set-add!
         (match expr
                [`(binary-operator . ,_)   binary-operators]
                [`(variadic-operator . ,_) variadic-operators]
                [`(variadic-predicate . ,_) variadic-predicates])
         op))
  "")

(define (compile-list expr)
  (match expr
         [`(elm-list . ,elements)
           (case (length elements)
             [(0) "[]"]
             [else (format "[ ~a ]"
                           (string-join (map compile-expr elements)
                                        ", "))])]))

(define (compile-tuple expr)
  (match expr
         [`(elm-tuple . ,elements)
           (case (length elements)
             [(0) "()"]
             [(1) (format "(~a)" (compile-expr (first elements)))]
             [else (format "( ~a )"
                           (string-join (map compile-expr elements)
                                        ", "))])]))

(define (compile-record expr)
  (match expr
         [`(elm-record . ,elements)
           (case (length elements)
             [(0) "{}"]
             [(1) (format "{ ~a }"
                          (format-record-field-value (first elements)))]
             [else (format "{ ~a }"
                           (string-join
                             (map (compose format-record-field-value
                                           compile-one-record-field)
                                  elements)
                             ", "))])]))

(define (compile-one-record-field pair)
  (match pair
         [`(,field ,value-or-type)
           `(,field ,(compile-expr value-or-type))]))

(define (compile-binary-operator expr)
  (match expr
         [`(,op ,a ,b)
           (format "~a ~a ~a"
                   (compile-expr a)
                   op
                   (compile-expr b))]))

(define (compile-variadic-operator expr)
  (match expr
         [`(,op . ,arguments)
           (string-join (map compile-expr arguments)
                        (format " ~a " op))]))

(define (compile-variadic-predicate expr)
  (match expr
         [`(,op ,a ,b . ,rest)
           (if (empty? rest)
             (format "~a ~a ~a"
                     (compile-expr a)
                     op
                     (compile-expr b))
             (format "~a ~a ~a && ~a"
                     (compile-expr a)
                     op
                     (compile-expr b)
                     (compile-variadic-predicate `(,op ,b ,@rest))))]))

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
                   (format-cases
                     (map compile-one-case cases)))]))

(define (compile-one-case case)
  (match case
         [`(,constructor ,value)
           `(,constructor ,(compile-expr value))]))

(define (compile-function-call expr)
 (format "~a ~a"
        (compile-expr (first expr))
        (string-join (map compile-expr (rest expr)) " ")))
