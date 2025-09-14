import gleam/list
import gleam_script/io
import gleam_script/project
import gleam_script/script
import shellout

const help_page = "[gleam_script]
One file scripts for Gleam.

commands:
- check  <FILE> : typecheck the script
- deps   <FILE> : list the dependencies
- export <FILE> : compile to escript
- run    <FILE> : run the script
- help          : show this page

options:
-v/--verbose
"

pub fn main() -> Nil {
  let #(args, verbose) =
    list.partition(shellout.arguments(), with: fn(arg) {
      arg != "-v" || arg != "--verbose"
    })
  let context = case list.length(verbose) {
    0 -> io.Normal
    _ -> io.Verbose
  }

  case args {
    ["check", file] -> {
      script.new(file)
      |> project.new(ctx: context)
      |> project.check
    }
    ["deps", file] -> {
      script.new(file)
      |> project.new(ctx: context)
      |> project.deps
    }
    ["export", file] -> {
      script.new(file)
      |> project.new(ctx: context)
      |> project.export
    }
    ["help", ..] -> {
      io.abort(msg: help_page, code: 0)
    }
    ["run", file] -> {
      script.new(file)
      |> project.new(ctx: context)
      |> project.run
    }
    _ -> io.abort(msg: "usage: gleam_script <command> <file>", code: 1)
  }
}
