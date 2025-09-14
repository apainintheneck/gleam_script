# gleam_script

[![Package Version](https://img.shields.io/hexpm/v/gleam_script)](https://hex.pm/packages/gleam_script)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleam_script/)

`gleam_script` allows using `gleam` as a scripting language by abstracting away the project repo. It only supports the Erlang as a target and requires any dependencies to be defined inline using comments. Scripts can be exported to `escript` files when ready.

## Usage

```
[gleam_script]
One file scripts for Gleam.

commands:
- check  <FILE> : typecheck the script
- deps   <FILE> : list the dependencies
- export <FILE> : compile to escript
- run    <FILE> : run the script
- help          : show this page

options:
-v/--verbose
```

## Example

````gleam
// ```gleam_deps
// gleam_stdlib
// simplifile
// ```

import gleam/io

pub fn main() -> Nil {
  io.println("Hello from gleam_script!")
}
`````

## Todo
1. Add support for the `new` and `clean` commands.
2. check if the dependencies are already defined before adding them.
3. Add integration tests.

Further documentation can be found at <https://hexdocs.pm/gleam_script>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
