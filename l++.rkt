#lang racket
; The L++ Programming Language
; L++ is a programming language that transcompiles to C++. It uses Lisp-like syntax.
; (C) 2014 KIM Taegyoon

(define version "0.1.1")
(define (readline)
  (read-line (current-input-port) 'any))

(displayln (format "L++ Compiler ~a (C) 2014 KIM Taegyoon" version))
(display "Code (EOF when done)> ")
(define code "")
(let loop ()
  (define line (readline))
  (unless (eof-object? line)
    (set! code (string-append code line "\n"))
    (loop)))

(set! code (string-append "(" code ")"))

;(displayln "Code:")
;(displayln code)
(define parsed (read (open-input-string code)))
;(displayln "Parsed:")
;(write parsed) (newline)

(define (compile-expr e)
  (cond [(list? e)
         (let ([f (first e)])
           (case f
             ; (include "file1.h" ...) => #include "file1.h" ...
             [(include) (string-join (for/list ([x (rest e)]) (format "#include ~s\n" x)) "")]
             ; (defn "int" main ("int argc" "char *argv[]") (return 0))
             [(defn) (format "~a ~a(~a) {\n~a;}\n" (list-ref e 1) (list-ref e 2) (string-join (list-ref e 3) ",") (string-join (map compile-expr (drop e 4)) ";\n"))]
             ; (def a 3 b 4.0 ...) => auto a = 3; auto b = 4.0; ...
             [(def) (string-join (for/list ([i (in-range 1 (length e) 2)]) (format "auto ~a=~a" (list-ref e i) (compile-expr (list-ref e (add1 i))))) ";\n")]
             ; (+ A B C ...) => (A + B + C + ...)
             [(+ - * / << >>) (string-join (map compile-expr (rest e)) (symbol->string f) #:before-first "(" #:after-last ")")]
             ; (++ A) => (A++)
             [(++ --) (format "(~a~a)" f (compile-expr (second e)))]
             ; (not A) => (!A)
             [(not) (format "(!~a)" (compile-expr (second e)))]
             ; (< A B) => (< A B)
             [(< <= > >= == != % = += -= *= /=) (format "(~a~a~a)" (compile-expr (second e)) f (compile-expr (third e)))]
             ; (and A B) => (&& A B)
             [(and) (format "(~a~a~a)" (compile-expr (second e)) "&&" (compile-expr (third e)))]
             ; (or A B) => (|| A B)
             [(or) (format "(~a~a~a)" (compile-expr (second e)) "||" (compile-expr (third e)))]             
             ; (return A) => return A
             [(return) (format "return ~a" (compile-expr (second e)))]
             ; (? TEST THEN ELSE) => (TEST ? THEN : ELSE)
             [(?) (format "(~a?~a:~a)" (compile-expr (second e)) (compile-expr (third e)) (compile-expr (fourth e)))]
             ; (if TEST THEN [ELSE]) => if (TEST) THEN; [else ELSE]
             [(if) (if (= (length e) 4) (format "if (~a) ~a; else ~a" (compile-expr (list-ref e 1)) (compile-expr (list-ref e 2)) (compile-expr (list-ref e 3)))
                       (format "if (~a) ~a" (compile-expr (list-ref e 1)) (compile-expr (list-ref e 2))))]
             ; (when TEST THEN ...) => if (TEST) {THEN; ...;}
             [(when) (format "if (~a) {\n~a;}" (compile-expr (list-ref e 1)) (string-join (map compile-expr (drop e 2)) ";\n"))]
             ; (while TEST BODY ...) => while (TEST) {BODY; ...;}
             [(while) (format "while (~a) {\n~a;}" (compile-expr (list-ref e 1)) (string-join (map compile-expr (drop e 2)) ";\n"))]
             ; (for INIT TEST STEP BODY ...) => for (INIT; TEST; STEP) {BODY; ...;}
             [(for) (format "for (~a; ~a; ~a) {\n~a;}" (compile-expr (list-ref e 1)) (compile-expr (list-ref e 2)) (compile-expr (list-ref e 3)) (string-join (map compile-expr (drop e 4)) ";\n"))]
             ; (foreach VAR CONTAINER BODY ...) => for (auto &VAR : CONTAINER) {BODY; ...;}
             [(foreach) (format "for (auto &~a : ~a) {\n~a;}" (compile-expr (second e)) (compile-expr (third e)) (string-join (map compile-expr (drop e 3)) ";\n"))]
             ; (do BODY ...) => {BODY; ...;}
             [(do) (format "{~a;}" (string-join (map compile-expr (rest e)) ";\n"))]
             ; (do/e EXPR ...) => (EXPR, ...)
             [(do/e) (string-join (map compile-expr (rest e)) "," #:before-first "(" #:after-last ")")]
             ; (at ARRAY POSITION) => ARRAY[POSITION]
             [(at) (format "~a[~a]" (second e) (compile-expr (third e)))]
             ; (break) => break
             [(break continue) (~a f)]
             ; (main BODY ...) => int main(int argc, char **argv) {BODY; ...}
             [(main) (format "int main(int argc, char **argv) {\n~a;}" (string-join (map compile-expr (rest e)) ";\n"))]
             ; (pr A ...) => std::cout << A << ...
             [(pr) (format "std::cout ~a" (string-join (for/list ([a (rest e)]) (~a "<< " (compile-expr a)))))]
             ; (prn A ...) => std::cout << A << ... << std::endl
             [(prn) (format "std::cout ~a << std::endl" (string-join (for/list ([a (rest e)]) (~a "<< " (compile-expr a)))))]
             ; (label ID) => ID:
             [(label) (format "~a:" (second e))]
             ; (goto ID) => goto ID
             [(goto) (format "goto ~a" (second e))]
             ; (switch EXPR BODY ...) => switch (EXPR) {BODY; ...;}
             [(switch) (format "switch (~a) {\n~a;}" (second e) (string-join (map compile-expr (drop e 2)) ";\n"))]
             ; (case EXPR ...) => case EXPR: case ...:
             [(case) (string-join (for/list ([x (rest e)]) (format "case ~a:" x)))]
             ; (default) => default:
             [(default) "default:"]
             ; (code "CODE") => CODE as-is
             [(code) (~a (second e))]
             ; (F ARG ...) => F(ARG, ...)
             [else (format "~a(~a)" f (string-join (map compile-expr (drop e 1)) ","))]))]
        [else (format (if (symbol? e) "~a" "~s") e)]))

(define prolog "#include <iostream>\n")
(define compiled (~a prolog (string-join (map compile-expr parsed) ";\n" #:after-last ";\n")))
(displayln "Compiled:")
(displayln compiled)
(define outsrc "a-out.cpp")
(define outbin "a-out")
(define out (open-output-file outsrc #:exists 'replace))
(displayln compiled out)
(close-output-port out)
(define dir (current-directory))
(displayln (format "Current directory: ~a" dir))
(displayln (format "Output written to: ~a" outsrc))
(when (system (format "g++ -std=c++11 -O3 -s -static -o ~a ~a" outbin outsrc))
  (displayln (format "Binary written to: ~a" outbin))
  (system (format "~a~a" dir outbin)))
