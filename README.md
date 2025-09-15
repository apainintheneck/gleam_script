# gleam_script

[![Package Version](https://img.shields.io/hexpm/v/gleam_script)](https://hex.pm/packages/gleam_script)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleam_script/)

`gleam_script` allows Gleam to be used as a scripting language by abstracting away the project repo. It only supports the Erlang target and requires any dependencies to be defined inline using comments. Scripts can be exported to `escript` files when ready.

## Usage

```
[gleam_script]
Project directories and dependency management are
abstracted away to bring one file scripts to Gleam.

commands:
- check  <FILE> : typecheck the script
- clean         : clean up all script files
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
// ```

import gleam/io

pub fn main() -> Nil {
  io.println("Hello from script!")
}
`````

## Todo
1. Add support for the `new` and `clean` commands.
2. check if the dependencies are already defined before adding them.
3. Add integration tests.
4. Commit an escript along with each release.

Further documentation can be found at <https://hexdocs.pm/gleam_script>.

## Development

```sh
gleam run   # Run the project
```
