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

### Download:

- [v0.0.4 (Linux 64bit)](https://raw.githubusercontent.com/Janiczek/elmlisp/0.0.4/dist/elmlisp)

### Compiling from source (also requires Racket!):

This will create an `elmlisp` binary in the src/ folder:

```
$ raco exe src/elmlisp.rkt
```

Alternatively, you can run the compiler with Racket interpreter instead of a binary, simply substitute `elmlisp` for `racket src/elmlisp.rkt` (this requires Racket).

----

### Structure of this repo

```
- src/
    - elmlisp.rkt - Application entrypoint. Run/compile this file.
    - format.rkt - Helper functions for how to emit Elm source code.
    - parse.rkt - Module concerned with how to read string with ElmLisp source code into s-expressions.
    - compile.rkt - The meat of the application. Compiles s-expressions into Elm source code strings.
    - helpers.rkt - Various helpers and predicates for the compiler.

- tests/ - Diff tests - input files and expected output files. Look here for examples of ElmLisp!

- run_tests.sh - Test runner watcher (runs test_runner.rkt when src/ or tests/ changes).
- test_runner.rkt - Script for running the test suite once.
 
```

----

### TODO

- [ ] some commandline friendliness, dude
- [ ] examples of macros
- [ ] Elm records, tuples, lists: [here's how **#lang clojure** does it](https://github.com/takikawa/racket-clojure/blob/master/clojure/reader.rkt#L28-L36)

- [ ] `(effect-module)` - read up on it, see what has to be specified. I suspect there is a potential macro lurking somewhere!
- [ ] `(type-alias)` with records
- [ ] `(case)` (tests) both with and without wildcard, and destructuring
- [ ] `(let)` (with destructuring too)

- [ ] comments
- [ ] destructuring in fn arguments
- [ ] destructuring in fn arguments - what about ADTs with one constructor?

- [ ] all the `(module)` definitions rendered at the top (it's technically an error, but the Elm compiler will tell you that)
- [ ] all the `(import)` definitions rendered at the top, sorted

- [ ] refactoring of `compile.rkt` into helper funtions in `format.rkt` (all the `(format "..." ...)` calls)
- [ ] maybe use `elm-format` on the result? cmd-line option for that?

- [ ] binary ops from base
- [ ] macro for specifying stuff as binary ops (ElmLisp can't know about library's operators)
- [ ] operators that are both binary and unary (`-`)

- [ ] how will #t and #f vs True and False play out in macros etc.?
- [ ] maybe try creating a `(where)` alternative to `(let)` as an macro, if that even makes sense in ElmLisp

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
