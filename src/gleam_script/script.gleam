import gleam/list
import gleam/string
import gleam_script/io

pub type Script {
  Script(path: String, contents: String, dependencies: List(String))
}

pub fn new(path: String) -> Script {
  let contents = io.read_file_or_abort(from: path)
  let dependencies = parse_dependencies(contents)

  io.abort_unless(
    msg: "error: missing dependencies",
    code: 1,
    unless: list.length(dependencies) > 0,
  )

  Script(path:, contents:, dependencies:)
}

fn parse_dependencies(contents: String) -> List(String) {
  contents
  |> string.split("\n")
  |> list.drop_while(fn(line) { !string.starts_with(line, "// ```gleam_deps") })
  |> list.drop(1)
  |> list.take_while(fn(line) { !string.starts_with(line, "// ```") })
  |> list.filter(fn(line) { string.starts_with(line, "//") })
  |> list.map(fn(line) { line |> string.drop_start(2) |> string.trim })
}
