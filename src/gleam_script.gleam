import gleam/list
import gleam_script/dir
import gleam_script/io
import gleam_script/project
import gleam_script/script
import shellout
import simplifile

const help_page = "[gleam_script]
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
"

pub fn main() -> Nil {
  let #(args, verbose) =
    list.partition(shellout.arguments(), with: fn(arg) {
      arg != "-v" && arg != "--verbose"
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
    ["clean"] -> {
      io.print_verbose("info: cleaning up cache directory", ctx: context)

      let cache_dir = dir.cache_dir()

      case simplifile.is_directory(cache_dir) {
        Ok(True) -> {
          simplifile.clear_directory(cache_dir)
          |> io.unwrap_or_abort(
            msg: "error: unable to delete cache_dir:\n" <> cache_dir,
            code: 1,
          )

          io.print_verbose(
            "info: deleted cache directory:\n" <> cache_dir,
            ctx: context,
          )
        }
        Ok(False) -> Nil
        Error(_) -> {
          io.abort(
            msg: "error: invalid permissions to check for the cache directory:\n"
              <> cache_dir,
            code: 1,
          )
        }
      }
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
    ["help"] -> {
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
