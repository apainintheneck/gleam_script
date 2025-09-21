import directories
import filepath
import gleam_script/io
import simplifile

pub fn cache_dir() -> String {
  directories.cache_dir()
  |> io.unwrap_or_abort(
    msg: "error: unable to determine XDG cache directory",
    code: 1,
  )
  |> filepath.join("gleam_script")
}

pub fn file_exists(path: String) -> Bool {
  simplifile.is_file(path)
  |> io.unwrap_or_abort(
    msg: "error: invalid permissions to check for the file:\n" <> path,
    code: 1,
  )
}

pub fn read_file_or_abort(from path: String) -> String {
  case simplifile.read(path) {
    Ok(contents) -> contents
    Error(_) -> {
      io.abort(msg: "error: unable to read file:\n" <> path, code: 1)
      panic as "unreachable"
    }
  }
}

pub fn write_file_or_abort(to path: String, contents contents: String) -> Nil {
  case simplifile.write(to: path, contents:) {
    Ok(_) -> Nil
    Error(_) -> io.abort(msg: "error: unable to write file:\n" <> path, code: 1)
  }
}
