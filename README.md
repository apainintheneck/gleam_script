# gleam_script

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

pub fn main() {
  io.println("Hello from script!")
}
`````

## Todo
1. check if the dependencies are already defined before adding them.
2. Add integration tests.
3. Commit an escript along with each release.

## Development

```sh
gleam run   # Run the project
```
