import filepath
import gleam/bit_array
import gleam/crypto
import gleam/dict
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import gleam_script/fs
import gleam_script/io.{type Context}
import gleam_script/script.{type Script}
import shellout
import simplifile
import tom

pub opaque type Project {
  Project(script: Script, context: Context, directory: String)
}

const internal_name = "script"

pub fn new(script: Script, ctx context: Context) -> Project {
  let project_name = hash(script.path)
  let cache_dir = fs.cache_dir()
  let project_dir = filepath.join(cache_dir, project_name)
  let project = Project(script:, context:, directory: project_dir)

  let success =
    simplifile.is_directory(project_dir)
    |> io.unwrap_or_abort(
      msg: "error: invalid permissions to check for the project directory:\n  "
        <> project_dir,
      code: 1,
    )

  case success {
    True -> {
      io.print_verbose("info: found existing project", ctx: context)
    }
    False -> {
      io.print_verbose("info: creating new project", ctx: context)
      init_directory(cache_directory: cache_dir, project_name:, ctx: context)
      init_config(project)
      delete_test_directory(project)
    }
  }

  update_content(project)
  update_dependencies(project)

  project
}

pub fn check(project: Project) -> Nil {
  io.print_verbose("info: linting project", ctx: project.context)

  command_or_abort(
    run: "gleam",
    with: ["check"],
    in: project.directory,
    log_output: False,
    ctx: project.context,
  )
}

pub fn deps(project: Project) -> Nil {
  io.print_verbose("info: showing dependencies", ctx: project.context)

  command_or_abort(
    run: "gleam",
    with: ["deps", "list"],
    in: project.directory,
    log_output: False,
    ctx: project.context,
  )
}

pub fn export(project: Project) -> Nil {
  io.print_verbose("info: exporting escript", ctx: project.context)

  let escript_path = filepath.strip_extension(project.script.path)

  case fs.file_exists(escript_path) {
    True ->
      io.confirm_or_abort(
        "A file already exists at:\n  "
        <> escript_path
        <> "\nWould you like to overwrite it? (y/n) ",
      )
    False -> Nil
  }

  command_or_abort(
    run: "gleam",
    with: ["add", "--dev", "gleescript"],
    in: project.directory,
    log_output: True,
    ctx: project.context,
  )

  command_or_abort(
    run: "gleam",
    with: ["build"],
    in: project.directory,
    log_output: True,
    ctx: project.context,
  )

  command_or_abort(
    run: "gleam",
    with: ["run", "-m", "gleescript"],
    in: project.directory,
    log_output: True,
    ctx: project.context,
  )

  simplifile.rename(
    filepath.join(project.directory, internal_name),
    escript_path,
  )
  |> io.unwrap_or_abort(
    msg: "error: unable to move escript to expected location:\n  "
      <> escript_path,
    code: 1,
  )
}

pub fn run(project: Project, with args: List(String)) -> Nil {
  io.print_verbose("info: run project", ctx: project.context)

  let exit_code =
    command(
      run: "gleam",
      with: ["run", "--", ..args],
      in: project.directory,
      log_output: False,
      ctx: project.context,
    )

  shellout.exit(exit_code)
}

fn init_directory(
  cache_directory directory: String,
  project_name name: String,
  ctx context: Context,
) -> Nil {
  io.print_verbose("info: creating project directory", ctx: context)
  let cache_dir = fs.cache_dir()

  simplifile.create_directory_all(cache_dir)
  |> io.unwrap_or_abort(
    msg: "error: unable to create cache directory:\n  " <> cache_dir,
    code: 1,
  )

  command_or_abort(
    run: "gleam",
    with: [
      "new",
      name,
      "--name",
      internal_name,
      "--template",
      "erlang",
      "--skip-git",
      "--skip-github",
    ],
    in: directory,
    log_output: True,
    ctx: context,
  )
}

const empty_config = "
name = \""
  <> internal_name
  <> "\"
version = \"1.0.0\"

[dependencies]

[dev-dependencies]

"

fn init_config(project: Project) -> Nil {
  fs.write_file_or_abort(
    to: filepath.join(project.directory, "gleam.toml"),
    contents: empty_config,
  )
}

fn delete_test_directory(project: Project) -> Nil {
  let test_dir =
    project.directory
    |> filepath.join("test")

  simplifile.delete(test_dir)
  |> io.unwrap_or_abort(
    msg: "error: unable to delete test directory:\n  " <> test_dir,
    code: 1,
  )
}

fn update_content(project: Project) -> Nil {
  io.print_verbose("info: checking project content", ctx: project.context)

  let old_text_path =
    list.fold(
      over: ["src", "script.gleam"],
      from: project.directory,
      with: filepath.join,
    )
  let old_text = fs.read_file_or_abort(from: old_text_path)
  let new_text = project.script.contents

  case hash(old_text) == hash(new_text) {
    True -> Nil
    False -> {
      io.print_verbose("info: updating project content", ctx: project.context)
      fs.write_file_or_abort(to: old_text_path, contents: new_text)
    }
  }
}

fn update_dependencies(project: Project) -> Nil {
  case has_dependencies(project) {
    True -> Nil
    False -> {
      io.print_verbose(
        "info: updating project dependencies",
        ctx: project.context,
      )

      command_or_abort(
        run: "gleam",
        with: ["add", ..project.script.dependencies],
        in: project.directory,
        log_output: True,
        ctx: project.context,
      )
    }
  }
}

fn has_dependencies(project: Project) -> Bool {
  io.print_verbose("info: checking project dependencies", ctx: project.context)

  case config_dependencies(project) {
    Ok(config_deps) -> {
      let config_deps = set.from_list(config_deps)
      list.all(project.script.dependencies, fn(dep) {
        set.contains(config_deps, dep)
      })
    }
    Error(_) -> False
  }
}

fn config_dependencies(project: Project) -> Result(List(String), Nil) {
  use contents <- result.try(
    filepath.join(project.directory, "gleam.toml")
    |> simplifile.read
    |> result.replace_error(Nil),
  )
  use toml <- result.try(
    tom.parse(contents)
    |> result.replace_error(Nil),
  )
  use deps <- result.try(
    tom.get_table(toml, ["dependencies"])
    |> result.replace_error(Nil),
  )

  Ok(dict.keys(deps))
}

fn command(
  run executable: String,
  with arguments: List(String),
  in directory: String,
  log_output log_output: Bool,
  ctx context: Context,
) -> Int {
  io.print_verbose(
    "$ " <> string.join([executable, ..arguments], with: " "),
    ctx: context,
  )

  let options = case log_output {
    True -> []
    False -> [shellout.LetBeStdout, shellout.LetBeStderr]
  }

  let status =
    shellout.command(
      run: executable,
      with: arguments,
      opt: options,
      in: directory,
    )

  let #(exit_code, output) = case status {
    Ok(output) -> #(0, output)
    Error(code_and_ouput) -> code_and_ouput
  }

  case string.is_empty(output) {
    True -> Nil
    False -> {
      io.print_verbose(
        output
          |> string.split(on: "\n")
          |> list.map(fn(line) { "| " <> line })
          |> string.join(with: "\n"),
        ctx: context,
      )
    }
  }

  exit_code
}

fn command_or_abort(
  run executable: String,
  with arguments: List(String),
  in directory: String,
  log_output log_output: Bool,
  ctx context: Context,
) -> Nil {
  let exit_code =
    command(
      run: executable,
      with: arguments,
      in: directory,
      log_output:,
      ctx: context,
    )

  let command_prefix =
    [executable, ..arguments]
    |> list.take(2)
    |> string.join(with: " ")

  io.abort_unless(
    msg: "error: running command internally:\n  " <> command_prefix,
    code: exit_code,
    unless: exit_code == 0,
  )
}

fn hash(str input: String) -> String {
  input
  |> bit_array.from_string
  |> crypto.hash(crypto.Sha1, _)
  |> bit_array.base16_encode
}
