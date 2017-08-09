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
(define (compile-expr e #:nested? [nested? #f])
  (cond

    ; Things that are not in (this kind of form)
    [(or (not (list? e)) (empty? e))
     (show-as-is e)]

    ; Expand macros and compile the result!
    [(set-member? macros (first e))
     (compile-expr (macroexpand-1 e))]

    ; Operators. We don't match on a fixed set of them because user can define his own / use library that defined one.
    [(set-member? binary-operators (first e))
     (compile-binary-operator e #:nested? nested?)]

    [(set-member? variadic-operators (first e))
     (compile-variadic-operator e #:nested? nested?)]

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
        [(let)         (compile-let e)]

        [else (compile-function-call e)])]))

(define (show-as-is expr)
  ((if (string? expr) ~s ~a) expr))

(define (handle-macro expr)
  (define (register-macro id expr)
    (set-add! macros id)
    (eval expr ns)
    "")
  (match expr
         [`(define-syntax ,id . ,_)
           (register-macro id expr)]

         [`(define-syntax (,id ,_) ,_)
           (register-macro id expr)]

         [`(define-syntax-rule (,id . ,_) . ,_)
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
             [else (format "{ ~a }"
                           (string-join
                             (map (compose format-record-pair-value
                                           compile-one-record-field)
                                  elements)
                             ", "))])]))

(define (compile-one-record-field pair)
  (match pair
         [`(,field ,value)
           `(,field ,(compile-expr value))]))

(define (compile-binary-operator expr #:nested? [nested? #f])
  (match expr
         [`(,op ,a ,b)
           (format (if nested? "(~a ~a ~a)" "~a ~a ~a")
                   (compile-expr a #:nested? #t)
                   op
                   (compile-expr b #:nested? #t))]))

(define (compile-variadic-operator expr #:nested? [nested? #f])
  (define format-string
    (if nested?
      "(~a ~a ~a)"
      "~a ~a ~a"))
  (match expr
         [`(,op ,a)
           (~a a)]

         [`(,op ,a ,(? list? b))
           (format format-string
                   (compile-expr a #:nested? #t)
                   op
                   (compile-expr b #:nested? #t))]

         [`(,op ,a ,b)
           (format format-string
                   (compile-expr a #:nested? #t)
                   op
                   (compile-expr b #:nested? #t))]

         [`(,op . ,arguments)
           (format (if nested? "(~a)" "~a")
                   (string-join
                     (map (lambda (sub-expr)
                            (compile-expr sub-expr #:nested? #t))
                          arguments)
                     (format " ~a " op)))]))

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
           (format "~a ~a =\n~a"
                   name
                   (format-arguments arguments)
                   (indent (compile-expr body)))]

         [`(defn ,name : ,type ,arguments ,body)
           (format "~a : ~a\n~a ~a =\n~a"
                   name
                   (format-type type)
                   name
                   (format-arguments arguments)
                   (indent (compile-expr body)))]))

(define (compile-if expr)
  (match expr
         [`(if ,condition ,then ,else)
           (format "if ~a then\n    ~a\nelse\n    ~a"
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

(define (compile-let expr)
  (match expr
         [`(let (elm-list . ,bindings) ,body)
           (begin
             (unless (not (empty? list))
               (raise-user-error "ERROR: A (let) form with empty bindings was found."))
             (unless (even? (length bindings))
               (raise-user-error "ERROR: A (let) form with uneven number of bindings was found."))
             (format "let\n~a\nin\n~a"
                     (indent (compile-bindings bindings))
                     (compile-expr body)))]))
                     

(define (compile-bindings bindings)
  (~>> bindings
       (in-slice 2)
       (sequence->list)
       (map compile-binding)
       (string-join _ "\n")))

(define (compile-binding binding)
  (match binding
         [`(,name ,value)
          (format "~a =\n    ~a"
                  name
                  (compile-expr value))]))

(define (compile-function-call expr)
  (format "~a ~a"
          (compile-expr (first expr))
          (string-join (map compile-expr (rest expr)) " ")))
