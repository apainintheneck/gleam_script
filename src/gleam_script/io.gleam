import gleam/io
import shellout
import simplifile

pub type Context {
  Normal
  Verbose
}

pub fn print_info(message: String) -> Nil {
  io.println(message)
}

pub fn print_verbose(message: String, ctx context: Context) -> Nil {
  case context {
    Normal -> Nil
    Verbose -> io.println(message)
  }
}

pub fn abort(msg message: String, code exit_code: Int) -> Nil {
  io.println(message)
  shellout.exit(exit_code)
}

pub fn abort_unless(
  msg message: String,
  code exit_code: Int,
  unless condition: Bool,
) -> Nil {
  case condition {
    True -> Nil
    False -> abort(msg: message, code: exit_code)
  }
}

pub fn unwrap_or_abort(
  result: Result(a, b),
  msg message: String,
  code exit_code: Int,
) -> a {
  case result {
    Ok(value) -> value
    Error(_) -> {
      abort(msg: message, code: exit_code)
      panic as "unreachable"
    }
  }
}

pub fn read_file_or_abort(from path: String) -> String {
  case simplifile.read(path) {
    Ok(contents) -> contents
    Error(_) -> {
      abort(msg: "error: unable to read file:\n" <> path, code: 1)
      panic as "unreachable"
    }
  }
}

pub fn write_file_or_abort(to path: String, contents contents: String) -> Nil {
  case simplifile.write(to: path, contents:) {
    Ok(_) -> Nil
    Error(_) -> abort(msg: "error: unable to write file:\n" <> path, code: 1)
  }
}
