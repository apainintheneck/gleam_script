# gleam_script

[![Package Version](https://img.shields.io/hexpm/v/gleam_script)](https://hex.pm/packages/gleam_script)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleam_script/)

`gleam_script` allows using `gleam` as a scripting language by abstracting away the project repo. It only supports the Erlang as a target and requires any dependencies to be defined inline using comments. Scripts can be exported to `escript` files when ready.

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
    a. Support these commands: `check`, `export`, `help`, `new`, `run`, `deps`, `clean`
        i. `new` will create a new internal project and script with the TOML header specifying gleam version and dependencies.
        ii. `run` will run the internal project with the equivalent main file to the script.
        iii. `export` will export an escript using `gleescript`
        iv. See https://gleam.run/command-line-reference
    b. `shellout` should be used to perform shell operations.
5. Substitute any file paths in the output with the original file path.
6. Consider adding `add`, `remove` and `update` commands to update dependencies.

The gleam version and dependencies will be specified as TOML metadata in comments. The gleam version is optional but dependencies are required before using them. Specifying the dependency versions is also optional though.

Consider using the `clip` argument parser.

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

Inline gleam.toml notes:
- Only the `gleam` and `dependencies` sections are supported.
    - Publisher metadata and target configuration are irrelevant.
- They must be wrapped in a code block with `gleam_script`.
- The advantage of using comments here is to preserve syntax highlighting and line numbers.

## Design

- `gleam_script.gleam`
    - main file
    - command line parsing
    - commands
- `gleam_script/project.gleam`
    - represents an internal project project
    - Type: `Project` (opaque)
        - `script: Script`
        - `context: Context`
    - Methods: `project`
        - `new(script: Script, context: Context) -> Repo`
            - find existing project based on path hash or create a new project using `gleam new`
            - update content
        - `check(project: Project)`
            - run `gleam check`
        - `run(project: Project)`
            - run `gleam run`
        - `clean(project: Project)`
            - delete all cached directories
        - `deps(project: Project)`
            - run `gleam deps`
        - `export(project: Project)`
    - Internal
        - Methods:
            - `command(project: Project, binary: String, args: List(String)) -> Result(String, #(Int, String), context: Context)`
                - Wrapper around the `shellout` library
                - Verbose logging of the command
                - Verbose logging of the output if it fails

Further documentation can be found at <https://hexdocs.pm/gleam_script>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
