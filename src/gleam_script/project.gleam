import filepath
import gleam/bit_array
import gleam/crypto
import gleam/dict
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import gleam_script/dir
import gleam_script/io.{type Context}
import gleam_script/script.{type Script}
import shellout
import simplifile
import tom

pub opaque type Project {
  Project(script: Script, context: Context, directory: String)
}

pub fn new(script: Script, ctx context: Context) -> Project {
  let project_name = hash(script.path)
  let cache_dir = dir.cache_dir()
  let project_dir = filepath.join(cache_dir, project_name)
  let project = Project(script:, context:, directory: project_dir)

  case simplifile.is_directory(project_dir) {
    Ok(True) -> {
      io.print_verbose("info: found existing project", ctx: context)
    }
    Ok(False) -> {
      io.print_verbose("info: creating new project", ctx: context)
      init_directory(cache_directory: cache_dir, project_name:, ctx: context)
      init_config(project)
      delete_test_directory(project)
    }
    Error(_) -> {
      io.abort(
        msg: "error: invalid permissions to check for the project directory:\n"
          <> project_dir,
        code: 1,
      )
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
    filepath.join(project.directory, "script"),
    filepath.strip_extension(project.script.path),
  )
  |> io.unwrap_or_abort(
    msg: "error: unable to move escript to expected location",
    code: 1,
  )
}

pub fn run(project: Project) -> Nil {
  io.print_verbose("info: run project", ctx: project.context)

  let exit_code =
    command(
      run: "gleam",
      with: ["run"],
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

  dir.cache_dir()
  |> simplifile.create_directory_all
  |> io.unwrap_or_abort(msg: "error: unable to create cache directory", code: 1)

  command_or_abort(
    run: "gleam",
    with: [
      "new",
      name,
      "--name",
      "script",
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
name = \"script\"
version = \"1.0.0\"

[dependencies]

[dev-dependencies]

"

fn init_config(project: Project) -> Nil {
  io.write_file_or_abort(
    to: filepath.join(project.directory, "gleam.toml"),
    contents: empty_config,
  )
}

fn delete_test_directory(project: Project) -> Nil {
  let res =
    project.directory
    |> filepath.join("test")
    |> simplifile.clear_directory

  let assert Ok(_) = res as "error: unable to delete test directory"

  Nil
}

fn update_content(project: Project) -> Nil {
  io.print_verbose("info: checking project content", ctx: project.context)

  let old_text_path =
    list.fold(
      over: ["src", "script.gleam"],
      from: project.directory,
      with: filepath.join,
    )
  let old_text = io.read_file_or_abort(from: old_text_path)
  let new_text = project.script.contents

  case hash(old_text) == hash(new_text) {
    True -> Nil
    False -> {
      io.print_verbose("info: updating project content", ctx: project.context)
      io.write_file_or_abort(to: old_text_path, contents: new_text)
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
    msg: "error: running command internally:\n" <> command_prefix,
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
