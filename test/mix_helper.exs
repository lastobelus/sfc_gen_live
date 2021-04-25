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
      Mix.Tasks.Phx.New.run(~w(sfc_gen_live --live))

      File.cd!("sfc_gen_live", fn ->
        func.()
      end)
    end)
  end

  def in_tmp_live_project(test, func) do
    in_tmp_project(test, fn ->
      File.mkdir_p!("lib")
      File.touch!("lib/sfc_gen_live_web.ex")
      File.touch!("lib/sfc_gen_live.ex")
      func.()
    end)
  end

  def in_tmp_live_umbrella_project(test, func) do
    in_tmp_umbrella_project(test, fn ->
      File.mkdir_p!("sfc_gen_live/lib")
      File.mkdir_p!("sfc_gen_live_web/lib")
      File.touch!("sfc_gen_live/lib/sfc_gen_live.ex")
      File.touch!("sfc_gen_live_web/lib/sfc_gen_live_web.ex")
      func.()
    end)
  end

  def in_tmp_project(which, function) do
    conf_before = Application.get_env(:sfc_gen_live, :generators) || []
    path = Path.join([tmp_path(), random_string(10), to_string(which)])

    try do
      File.rm_rf!(path)
      File.mkdir_p!(path)

      File.cd!(path, fn ->
        File.touch!("mix.exs")
        function.()
      end)
    after
      File.rm_rf!(path)
      Application.put_env(:sfc_gen_live, :generators, conf_before)
    end
  end

  def in_tmp_umbrella_project(which, function) do
    conf_before = Application.get_env(:sfc_gen_live, :generators) || []
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
      Application.put_env(:sfc_gen_live, :generators, conf_before)
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
    Application.put_env(:sfc_gen_live, :generators, new_env)

    try do
      fun.()
    after
      Application.delete_env(:sfc_gen_live, :generators)
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
end
