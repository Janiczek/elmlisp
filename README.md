# L++: The L++ Programming Language #

(C) 2014 Kim, Taegyoon

L++ is a programming language that transcompiles to C++. It uses Lisp-like syntax.

## Syntax and semantics ##
See [the source code](https://bitbucket.org/ktg/l/src).

### Comment ###
`;` `#!` end-of-line comment

`#|` nestable block comment `|#`

`#;` S-expression comment

See [Reading Comments](http://docs.racket-lang.org/reference/reader.html?q=%23%7C&q=comment#%28part._parse-comment%29).

## Examples ##
### Hello, World! ###
```
(main
  (prn "Hello, World!"))
```

### Other examples ###

Other examples are in the [`ex` directory](https://bitbucket.org/ktg/l/src).

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
