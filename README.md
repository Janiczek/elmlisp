# L++: The L++ Programming Language #

(C) 2014 Kim, Taegyoon

L++ is a programming language that transcompiles to C++. It uses Lisp-like syntax.

## Usage ##
```
#!sh

$ racket l++.rkt -h
l++.rkt [ <option> ... ] [<filenames>] ...
 where <option> is one of
  -c, --compile : Compile only; do not run
  -v, --verbose : Display verbose messages
  -o <file> : Place the output into <file>
  --help, -h : Show this help
  -- : Do not treat any remaining argument as a switch (at this level)
 Multiple single-letter switches can be combined after one `-'; for
  example: `-h-' is the same as `-h --'
```

## Syntax and semantics ##
`(define-syntax ...)` ; defines a macro

`(define-syntax-rule (id . pattern) template)` ; defines a macro

`(defmacro id formals body ...+)` ; defines a (non-hygienic) macro id through a procedure that manipulates S-expressions, as opposed to syntax objects.

`(include "file1.h" ...)` => `#include "file1.h" ...`

`(defn int main (int argc char **argv) (...))` => `int main(int argc, char **argv) {...}`

`(def a 3 b 4.0 ...)` => `auto a = 3; auto b = 4.0; ...`

`(decl TYPE VAR [VAL])` => `TYPE VAR[=VAL]` ; declares a variable

`(+ A B C ...)` => `(A + B + C + ...)` (`+ - * / << >>`)

`(++ A)` => `(++ A)` ; unary operators (`++ -- not compl`)

`(< A B)` => `(A < B)` ; binary operators (`< <= > >= == != % = += -= *= /= %= and and_eq bitand bitor not_eq or or_eq xor xor_eq`)

`(return A)` => `return A`

`(? TEST THEN ELSE)` => `(TEST ? THEN : ELSE)`

`(if TEST THEN [ELSE])` => `if (TEST) THEN; [else ELSE]`

`(when TEST THEN ...)` => `if (TEST) {THEN; ...;}`

`(while TEST BODY ...)` => `while (TEST) {BODY; ...;}`

`(for INIT TEST STEP BODY ...)` => `for (INIT; TEST; STEP) {BODY; ...;}`

`(foreach VAR CONTAINER BODY ...)` => `for (auto &VAR : CONTAINER) {BODY; ...;}`

`(do BODY ...)` => `{BODY; ...;}`

`(do/e EXPR ...)` => `(EXPR, ...)`

`(at ARRAY POSITION)` => `ARRAY[POSITION]`

`(break)` => `break` (`break continue`)

`(main BODY ...)` => `int main(int argc, char **argv) {BODY; ...; return 0;}`

`(pr A ...)` => `std::cout << A << ...`

`(prn A ...)` => `std::cout << A << ... << std::endl`

`(label ID)` => `ID:`

`(goto ID)` => `goto ID`

`(switch EXPR BODY ...)` => `switch (EXPR) {BODY; ...;}`

`(case EXPR ...)` => `case EXPR: case ...:`

`(default)` => `default:`

`(fn (int a int b) (return (+ a b)))` => `[&](int a, int b) {return a + b;}`

`(code "CODE")` => `CODE` as-is

`(format form ...)` ; compile-time formatting

`(F ARG ...)` => `F(ARG, ...)`

`#\A` => `'A'`

`|CODE|` => `CODE` as-is

See [the source code](https://bitbucket.org/ktg/l/src) for details.

### Comments ###
`;` `#!` end-of-line comment

`#|` nestable block comment `|#`

`#;` S-expression comment

See [Reading Comments](http://docs.racket-lang.org/reference/reader.html?q=%23%7C&q=comment#%28part._parse-comment%29).

### Macros ###
Macros are supported via [Racket's macro system](http://docs.racket-lang.org/guide/macros.html) [`define-syntax`](http://docs.racket-lang.org/reference/define.html?q=define-syntax#%28form._%28%28lib._racket%2Fprivate%2Fbase..rkt%29._define-syntax%29%29), [`define-syntax-rule`](http://docs.racket-lang.org/search/index.html?q=define-syntax-rule&q=define-syntax-rule&q=set-add%21&q=define-syntax&q=set&q=append&q=list-append&q=for&q=define-syntax) and [`defmacro`](http://docs.racket-lang.org/compatibility/defmacro.html).

## Examples ##
### Hello, World! ###
```
(main
  (prn "Hello, World!"))
```

Run with

```
#!sh

$ racket l++.rkt ex/hello.lpp
Hello, World!
```

### Other examples ###

Other examples are in the [`ex` directory](https://bitbucket.org/ktg/l/src).

[L++ on Rosetta Code](http://rosettacode.org/wiki/L++)

### [99 Bottles of Beer](http://en.wikipedia.org/wiki/99_Bottles_of_Beer) ###
```
(main
  (for (def i 99) (>= i 1) (-- i)
    (prn i " bottles of beer on the wall, " i " bottles of beer.")
    (prn "Take one down and pass it around, " (- i 1) " bottle of beer on the wall.")))
```

## License ##

   Copyright 2014 Kim, Taegyoon

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
