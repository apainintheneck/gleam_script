# gscript

[![Package Version](https://img.shields.io/hexpm/v/gscript)](https://hex.pm/packages/gscript)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gscript/)

`gscript` allows using `gleam` as a scripting language by abstracting away the project repo. It only supports the Erlang as a target and requires any dependencies to be defined inline using comments. Scripts can be exported to `escript` files when ready.

## Todo

When first run the app will create a config directory using the `directories` library.

The app will work like this.

1. Read the script file into memory.
    a. `simplifile` is probably fine here though `file_streams` could also be used.
2. Hash the script file content.
    a. `gleam_crypto` should work well here and even includes a streaming option
3. Check if an internal project exists for that file hash and path.
    a. If one doesn't exist, create it with `gleam new`.
    b. Store the file hash and path to project in a TOML config file.
    c. Copy the script file content to the `src/main.gleam` file.
4. Run the command on the project.
    a. Support these commands: `check`, `clean`, `deps`, `export`, `fix`, `format`, `help`, `new`, `run`
        i. `new` will create a new internal project and script with the TOML header specifying gleam version and dependencies.
        ii. `run` will run the internal project with the equivalent main file to the script.
        iii. `export` will export an escript using `gleescript`
        iv. See https://gleam.run/command-line-reference
    b. `shellout` should be used to perform shell operations.
5. Substitute any file paths in the output with the original file path.

The gleam version and dependencies will be specified as TOML metadata in comments.

```gleam
//gscript>
// gleam = ">= 0.34.0"
//
// [dependencies]
// gleam_stdlib = ">= 0.47.0 and < 2.0.0"
//gscript<

import gleam/io

pub fn main() -> Nil {
  io.println("Hello from gscript!")
}
```

Inline gleam.toml notes:
- Only the `gleam` and `[dependencies]` sections are supported.
    - Publisher metadata and target configuration are irrelevant.
- They must be wrapped in `//gscript>` and `//gscript<` lines.
- The advantage of using comments here is to preserve syntax highlighting and line numbers.

Further documentation can be found at <https://hexdocs.pm/gscript>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
