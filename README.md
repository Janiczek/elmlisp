# ElmLisp
> An experimental LISP syntax for Elm language, and an ElmLisp → Elm transpiler. 

----

What this enables us is one simple thing: **macros** and thus, less boilerplate!

A small example:

```racket
(module Main)

(type-alias Model Int)

(type Msg
  Inc
  (DecBy Int))

(def init : Model
  0)

(defn decBy : (-> Int Model Model)
  (amount model)
  (- model amount))
```

becomes... (or, at least, it should when I'm done implementing it :sweat_smile:)

```elm
module Main exposing (..)

type alias Model =
    Int

type Msg
    = Inc
    | DecBy Int

init : Model
init =
    0

decBy : Int -> Model -> Model
decBy amount model =
    model - amount
```

So far, this is just a different syntax for Elm, and in itself is not worth writing in (at least I wouldn't!). **Being a LISP, though,** we can use macros to get rid of some boilerplate! Let's see:

**TODO:** example of macro usage!

----

### Usage:

You can read input code from STDIN:
```
$ elmlisp
```

Or from a file:
```
$ elmlisp input.ell
```

You can run the compiler with Racket interpreter instead of a binary, simply substitute `elmlisp` for `racket src/elmlisp.rkt` (this requires Racket).

### Compiling from source (also requires Racket!):

```
$ raco exe src/elmlisp.rkt
```

Will create an `elmlisp` binary in your current directory.

----

### Structure of this repo

```
- elm-examples/
    - all-syntax.ell - All possible (implemented and planned) syntax for ElmLisp, this is my
                       input file when developing...

- run_tests.sh - Test runner.
- tests/ - Diff tests - input files and expected output files.

 
- src/
    - elmlisp.rkt - Application entrypoint. Run/compile this file.
    - format.rkt - Helper functions for how to emit Elm source code.
    - parse.rkt - Module concerned with how to read string with ElmLisp source code into s-expressions.
                  (How to read commas? How to read [] {} #[]? Etc.)
    - compile.rkt - The meat of the application. Recursively compiles various s-expressions
                    into Elm source code strings.
```

----

### TODO

- [ ] tests (`lambda.in` -> `lambda.out`, diff with compiler output) for various language constructs
- [ ] refactoring of `compile.rkt` into helper funtions in `format.rkt` (all the `(format "..." ...)` calls)

----

### Acknowledgements:

- [L++](https://bitbucket.org/ktg/l) by Kim Taegyoon - ElmLisp project is mostly a derivate of L++, repurposed to emit Elm instead of C++! Thank you!
- [Racket](https://racket-lang.org/) - ElmLisp project is implemented using Racket, and uses Racket's macro system for its own macro syntax. So, thank you! :)
- [Elm](http://elm-lang.org/) - Obviously, Elm is what we compile to. Thank you Evan for such a beautiful language!

----

### License:

Copyright 2017 Martin Janiczek

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
