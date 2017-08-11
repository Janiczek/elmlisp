# ElmLisp
An experimental LISP syntax for Elm language, and an ElmLisp → Elm transpiler. 

----

> But why???

Because of one simple thing: **macros!** -- and thus, less boilerplate!

----

ElmLisp looks like this:

```racket
(module Main)

(type-alias Model Int)

(defn inc : (-> Model Model)
  [model]
  (+ model 1))
```

Which becomes...

```elm
module Main exposing (..)

type alias Model =
    Int

inc : Model -> Model
inc model =
    model + 1
```

So far, this is just a different syntax for Elm, and in itself is probably not worth writing in. **Being a LISP, though,** we can use macros to get rid of some boilerplate! Let's see, a hypothetical macro could turn:

```racket
(msg-and-update
  (Inc         Inc            (+ model 1))
  ((DecBy Int) (DecBy amount) (- model amount))
  (Reset       Reset          0))
```

into:

```elm
type Msg
    = Inc
    | DecBy Int
    | Reset

update msg model =
    case msg of
        Inc ->
            model + 1

        DecBy amount ->
            model - amount

        Reset ->
            0
```

**TODO:** think of a more believable macro ;) and finish this section.

----

### Download [here!](https://github.com/Janiczek/elmlisp/releases)

### Usage:

- Read input code from STDIN: `$ elmlisp`
- Or from a file: `$ elmlisp input.ell`
- Format the result with [elm-format](https://github.com/avh4/elm-format): `$ elmlisp -f`
- Output to a file: `$ elmlisp -o Output.elm`
- Display help: `$ elmlisp -h`

If you have [Racket installed](https://download.racket-lang.org/):

- You can run ElmLisp interpreted: `$ racket src/elmlisp.rkt`
- Or compile it from source: `$ raco exe src/elmlisp.rkt`

----

### Structure of this repo

```
- src/
    - elmlisp.rkt - Application entrypoint. Run/compile this file.
    - format.rkt - Helper functions for how to emit Elm source code.
    - parse.rkt - Module concerned with how to read string with ElmLisp source code into s-expressions.
    - compile.rkt - The meat of the application. Compiles s-expressions into Elm source code strings.
    - helpers.rkt - Various helpers and predicates for the compiler.

- examples/ - Examples just for you :) Largely complete Elm modules showcasing ElmLisp.
- tests/ - Diff tests - input files and expected output files. Look here for examples of ElmLisp!

- run_tests.sh - Test runner watcher (runs test_runner.rkt when src/ or tests/ changes).
- test_runner.rkt - Script for running the test suite once.
```

----

### TODO

#### Minimum Viable Product

- examples of macros
- comments (either make `;` stay in the Elm code as `--`, or have `(-- ...)` or something)
- destructuring (in fn arguments, let and other places, ADTs with one constructor, etc.)
- record updating
- extensible records!

#### Nice to have
- somehow break up long lines (eg. any substantial `view` function)
- all the `(module)` definitions rendered at the top (it's technically an error, but we let the Elm compiler tell you that)
- all the `(import)` definitions rendered at the top, sorted (even if some macro called it in the middle of the file)

#### Meh
- `(effect-module)` - read up on it, see what has to be specified. I suspect there is a potential macro lurking somewhere!
- refactoring of `compile.rkt` into helper funtions in `format.rkt` (all the `(format "..." ...)` calls)

#### Research
- import of other ElmLisp files? (just of their macros?)
- how will `#t` and `#f` vs `True` and `False` play out in macros etc.?
- maybe try creating a `(where)` alternative to `(let)` as an macro, if that even makes sense in ElmLisp

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
