import gleam/io
import gleam/string
import input
import shellout

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
    Error(err) -> {
      io.println(message)
      io.println("inspect: " <> string.inspect(err))
      shellout.exit(exit_code)
      panic as "unreachable"
    }
  }
}

pub fn confirm_or_abort(prompt: String) -> Nil {
  let response =
    input.input(prompt:)
    |> unwrap_or_abort(msg: "error: unable to get user input", code: 1)
    |> string.trim
    |> string.lowercase

  case response {
    "y" | "yes" -> Nil
    _ -> abort(msg: "...exiting program...", code: 1)
  }
}
