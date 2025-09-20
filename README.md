# gleam_script

`gleam_script` allows Gleam to be used as a scripting language by abstracting away the project repo. It only supports the Erlang target and requires any dependencies to be defined inline using comments. Scripts can be exported to `escript` files when ready.

## Usage

```
[gleam_script]
Project directories and dependency management are
abstracted away to bring one file scripts to Gleam.

commands:
- new    <FILE> : generate a template script
- run    <FILE> : run the script
- export <FILE> : compile to escript
- check  <FILE> : typecheck the script
- deps   <FILE> : list the dependencies
- clean         : clean up all internal files
- help          : show this page

options:
-v/--verbose
```

## Example

````gleam
// Add more dependencies to gleam_deps below: one per line.
//
// ```gleam_deps
// gleam_stdlib
// ```

import gleam/io

pub fn main() {
  io.println("Hello from script!")
}
`````

## Todo
1. Add integration tests.
2. Commit an escript along with each release.

## Development

```sh
gleam run   # Run the project
```
