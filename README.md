# gleam_script

`gleam_script` allows Gleam to be used as a scripting language by abstracting away the project repo. It only supports the Erlang target and requires any dependencies to be defined inline using comments. Scripts can be exported to `escript` files when ready.

## Usage

```
[gleam_script]
Project directories and dependency management are
abstracted away to bring one file scripts to Gleam.

commands:
- new    <file>              : generate a script
- run    <file> -- <args>... : run a script
- export <file>              : compile to an escript
- check  <file>              : typecheck a script
- deps   <file>              : list the dependencies
- clean                      : clean up cached files
- help                       : show this page

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

Note: Specifying dependency versions is not planned to keep things simple.

## Development

```sh
gleam run     # Run the project
make          # Lint and test the project
make lint     # Lint the project
make test     # Test the project
make clean    # Delete the test directory
make release  # Create an escript
```
