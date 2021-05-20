#  Copied from  https://github.com/phoenixframework/phoenix.git

# Get Mix output sent to the current
# process to avoid polluting tests.
Mix.shell(Mix.Shell.Process)

# Mock live reloading for testing the generated application.
defmodule Phoenix.LiveReloader do
  def init(opts), do: opts
  def call(conn, _), do: conn
end

defmodule MixHelper do
  import ExUnit.Assertions
  import ExUnit.CaptureIO

  @app_name :sfc_gen_live
  @test_app_name :sfc_gen_live_test

  def tmp_path do
    Path.expand("../../tmp", __DIR__)
  end

  defp random_string(len) do
    len |> :crypto.strong_rand_bytes() |> Base.encode64() |> binary_part(0, len)
  end

  def in_tmp(which, function) do
    path = Path.join([tmp_path(), random_string(10), to_string(which)])

    try do
      File.rm_rf!(path)
      File.mkdir_p!(path)
      File.cd!(path, function)
    after
      File.rm_rf!(path)
    end
  end

  def in_generated_phoenix_live_project(test, func) do
    in_tmp_project(test, fn ->
      send(self(), {:mix_shell_input, :yes?, false})
      Mix.Tasks.Phx.New.run(~w(#{@app_name} --live))

      File.cd!(to_string(@app_name), fn ->
        func.()
      end)
    end)
  end

  def in_tmp_phx_project(test, func, deps \\ [:phoenix]) do
    app = @test_app_name

    in_tmp_project(test, fn ->
      File.write!("mix.exs", mixfile_contents(app, deps))

      func.()
    end)
  end

  def in_tmp_live_umbrella_project(test, func) do
    in_tmp_umbrella_project(test, fn ->
      File.mkdir_p!("#{@app_name}/lib")
      File.mkdir_p!("#{@app_name}_web/lib")
      File.touch!("#{@app_name}/lib/#{@app_name}.ex")
      File.touch!("#{@app_name}_web/lib/#{@app_name}_web.ex")
      func.()
    end)
  end

  def in_tmp_project(which, function) do
    in_tmp_project(which, [], function)
  end

  def in_tmp_project(which, deps, function) do
    conf_before = Application.get_env(@app_name, :generators) || []
    path = Path.join([tmp_path(), random_string(10), to_string(which)])
    project_deps_path = Mix.Project.deps_path()
    project_build_path = Mix.Project.build_path()

    try do
      File.rm_rf!(path)
      File.mkdir_p!(path)

      File.cd!(path, fn ->
        File.mkdir_p!("lib")
        File.mkdir_p!("_build")
        File.mkdir_p!("test")
        File.write!("mix.exs", mixfile_contents(@test_app_name, deps))
        File.write!("test/test_helper.exs", "ExUnit.start()\n")

        unless Enum.empty?(deps) do
          # can't copy mix.lock because I think the hashes include the file creation date,
          # but copying all deps & build from the parent project takes less (1/2) time when
          # the test requires any of them, even though it recompiles.
          # Enum.each(deps, fn dep -> copy_dep(dep, project_deps_path, project_build_path) end)
          # I also tried copying deps/builds with `System.cmd("cp -a") but still get a
          # dependencies out of date error with copied mix file and no "mix deps.get"

          deps_path = Mix.Project.deps_path()
          build_path = Mix.Project.build_path()

          File.cp_r!(
            project_build_path,
            build_path
          )

          File.cp_r!(
            project_deps_path,
            deps_path
          )
        end

        function.()
      end)
    after
      File.rm_rf!(path)
      Application.put_env(@app_name, :generators, conf_before)
    end
  end

  def in_tmp_umbrella_project(which, function) do
    conf_before = Application.get_env(@app_name, :generators) || []
    path = Path.join([tmp_path(), random_string(10), to_string(which)])

    try do
      apps_path = Path.join(path, "apps")
      config_path = Path.join(path, "config")
      File.rm_rf!(path)
      File.mkdir_p!(path)
      File.mkdir_p!(apps_path)
      File.mkdir_p!(config_path)
      File.touch!(Path.join(path, "mix.exs"))

      for file <- ~w(config.exs dev.exs test.exs prod.exs prod.secret.exs) do
        File.write!(Path.join(config_path, file), "use Mix.Config\n")
      end

      File.cd!(apps_path, function)
    after
      Application.put_env(@app_name, :generators, conf_before)
      File.rm_rf!(path)
    end
  end

  def in_project(app, path, fun) do
    %{name: name, file: file} = Mix.Project.pop()

    try do
      capture_io(:stderr, fn ->
        Mix.Project.in_project(app, path, [], fun)
      end)
    after
      Mix.Project.push(name, file)
    end
  end

  def assert_file(file) do
    assert File.regular?(file), "Expected #{file} to exist, but does not"
  end

  def refute_file(file) do
    refute File.regular?(file), "Expected #{file} to not exist, but it does"
  end

  def assert_file(file, match) do
    cond do
      is_list(match) ->
        assert_file(file, &Enum.each(match, fn m -> assert &1 =~ m end))

      is_binary(match) or Regex.regex?(match) ->
        assert_file(file, &assert(&1 =~ match))

      is_function(match, 1) ->
        assert_file(file)
        match.(File.read!(file))

      true ->
        raise inspect({file, match})
    end
  end

  def with_generator_env(new_env, fun) do
    Application.put_env(@app_name, :generators, new_env)

    try do
      fun.()
    after
      Application.delete_env(@app_name, :generators)
    end
  end

  def mixfile_contents(app, deps \\ []) do
    """
    defmodule #{Macro.camelize(to_string(app))}.Mixfile do
      use Mix.Project

      def project do
        [app: #{inspect(app)}, version: "0.1.0", deps: deps()]
      end

      def application do
        [applications: [:logger]]
      end

      defp deps do
        #{inspect(Enum.map(deps, &get_dep/1))}
      end
    end
    """
  end

  def get_dep(dep) when is_tuple(dep), do: dep

  def get_dep(dep) when is_atom(dep) do
    {dep, Keyword.get(Mix.Project.config()[:deps], dep)}
  end

  def copy_dep(dep, project_deps_path, project_build_path) do
    deps_path = Mix.Project.deps_path()
    build_path = Mix.Project.build_path()

    dep =
      cond do
        is_tuple(dep) ->
          dep
          |> Tuple.to_list()
          |> List.first()
          |> Kernel.to_string()

        true ->
          to_string(dep)
      end

    IO.puts("project_deps_path: #{inspect(project_deps_path)}")
    IO.puts("dep: #{inspect(dep)}")
    proj_dep = Path.join(project_deps_path, dep)
    proj_build = Path.join([project_build_path, "lib", dep])

    test_dep = Path.join(deps_path, dep)
    test_build = Path.join([build_path, "lib", dep])

    IO.puts("copying \n`#{proj_dep}`\nto\n`#{test_dep}` >> #{File.exists?(proj_dep)}")

    if File.exists?(proj_dep) do
      File.cp_r!(proj_dep, test_dep)
    end

    IO.puts("copying \n`#{proj_build}`\nto\n`#{test_build}` >> #{File.exists?(proj_build)}")

    if File.exists?(proj_build) do
      File.cp_r!(proj_build, test_build)
    end
  end

  def umbrella_mixfile_contents do
    """
    defmodule Umbrella.MixProject do
      use Mix.Project

      def project do
        [
          apps_path: "apps",
          deps: deps()
        ]
      end

      defp deps do
        []
      end
    end
    """
  end

  def flush do
    receive do
      _ -> flush()
    after
      0 -> :ok
    end
  end

  def run_mix_test(test, opts \\ []) do
    if opts[:verbose] do
      IO.puts("compiling tmp_project for `#{test}`...")
    end

    {output, _exit_status} = System.cmd("mix", ~w(test), stderr_to_stdout: true)
    [deps_build_output | test_output] = String.split(output, "==> #{@test_app_name}\nCompiling")

    cond do
      length(test_output) < 1 ->
        {:error, deps_build_output}

      true ->
        {:ok, Enum.join(test_output)}
    end
  end

  def inspect_app_dir(also \\ nil) do
    IO.puts("----------------------------------------------")
    IO.puts("File.cwd!(): #{inspect(File.cwd!())}")
    IO.puts("File.ls!(): #{inspect(File.ls!())}")

    if also do
      IO.puts("File.ls!(#{also}): #{inspect(File.ls!(also))}")
    else
      {tree, _x} = System.cmd("tree", [])
      IO.puts(tree)
    end

    # hi
    IO.puts("----------------------------------------------")
  end
end
