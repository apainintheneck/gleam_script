import directories
import filepath
import gleam_script/io

pub fn cache_dir() -> String {
  directories.cache_dir()
  |> io.unwrap_or_abort(
    msg: "error: unable to determine XDG cache directory",
    code: 1,
  )
  |> filepath.join("gleam_script")
}
