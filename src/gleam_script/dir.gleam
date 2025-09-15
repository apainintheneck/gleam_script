import directories
import filepath
import gleam_script/io

pub fn cache_dir() -> String {
  case directories.cache_dir() {
    Ok(dir) -> filepath.join(dir, "gleam_script")
    Error(_) -> {
      io.abort(msg: "error: unable to determine XDG cache directory", code: 1)
      panic as "unreachable"
    }
  }
}
