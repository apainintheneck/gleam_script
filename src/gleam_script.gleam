import argv
import gleam/list
import gleam_script/fs
import gleam_script/io
import gleam_script/project
import gleam_script/script
import simplifile

const help_page = "[gleam_script]
Project directories and dependency management are
abstracted away to bring one file scripts to Gleam.

commands:
  new    <file>              : generate a script
  run    <file> -- <args>... : run a script
  export <file>              : compile to an escript
  check  <file>              : typecheck a script
  deps   <file>              : list the dependencies
  clean                      : clean up cached files
  help                       : show this page

options:
-v/--verbose
"

const gleam_script_template = "// Add more dependencies to gleam_deps below: one per line.
//
// ```gleam_deps
// gleam_stdlib
// ```

import gleam/io

pub fn main() {
  io.println(\"Hello from script!\")
}
"

pub fn main() -> Nil {
  let args = parse_args()
  case args.list {
    ["check", file] -> {
      script.new(file)
      |> project.new(ctx: args.context)
      |> project.check
    }
    ["clean"] -> {
      io.print_verbose("info: cleaning up cache directory", ctx: args.context)

      let cache_dir = fs.cache_dir()

      case simplifile.is_directory(cache_dir) {
        Ok(True) -> {
          simplifile.delete(cache_dir)
          |> io.unwrap_or_abort(
            msg: "error: unable to delete cache directory:\n  " <> cache_dir,
            code: 1,
          )

          io.print_verbose(
            "info: deleted cache directory:\n  " <> cache_dir,
            ctx: args.context,
          )
        }
        Ok(False) -> Nil
        Error(_) -> {
          io.abort(
            msg: "error: invalid permissions to check for the cache directory:\n  "
              <> cache_dir,
            code: 1,
          )
        }
      }
    }
    ["deps", file] -> {
      script.new(file)
      |> project.new(ctx: args.context)
      |> project.deps
    }
    ["export", file] -> {
      script.new(file)
      |> project.new(ctx: args.context)
      |> project.export
    }
    ["help"] -> {
      io.abort(msg: help_page, code: 0)
    }
    ["new", file] -> {
      case fs.file_exists(file) {
        True ->
          io.confirm_or_abort(
            "A file already exists at:\n  "
            <> file
            <> "\nWould you like to overwrite it? (y/n) ",
          )
        False -> Nil
      }

      io.print_verbose(
        "info: creating gleam_script template file:\n  " <> file,
        ctx: args.context,
      )
      fs.write_file_or_abort(to: file, contents: gleam_script_template)
    }
    ["run", file] -> {
      script.new(file)
      |> project.new(ctx: args.context)
      |> project.run(with: args.extra)
    }
    _ -> io.abort(msg: "usage: gleam_script <command> <file>", code: 1)
  }
}

type Arguments {
  Arguments(list: List(String), extra: List(String), context: io.Context)
}

fn parse_args() -> Arguments {
  let #(args, verbose) =
    list.partition(argv.load().arguments, with: fn(arg) {
      arg != "-v" && arg != "--verbose"
    })
  let #(list, extra) =
    list.split_while(args, satisfying: fn(arg) { arg != "--" })
  let extra = extra |> list.drop(1)
  let context = case list.length(verbose) {
    0 -> io.Normal
    _ -> io.Verbose
  }
  Arguments(list:, extra:, context:)
}
