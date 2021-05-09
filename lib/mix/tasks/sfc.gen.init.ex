defmodule Mix.Tasks.Sfc.Gen.Init do
  @moduledoc """
  Generates a Surface component.
  """
  use Mix.Task

  @switches [
    template: :boolean,
    namespace: :string,
    demo: :boolean,
    context_app: :string
  ]
  @default_opts [
    template: true,
    namespace: "components",
    demo: true
  ]
  @aliases [t: :template, n: :namespace, d: :demo]
  @doc false
  def run(args) do
    opts = parse_opts(args)

    namespace_parts = validate_namespace!(opts[:namespace])

    assigns = Mix.SfcGenLive.inflect(namespace_parts, "card") ++ opts

    inject_in_formatter_exs()
    inject_live_reload_config(assigns[:web_path])
    inject_in_app_web_view_macro(assigns[:web_module_path])

    maybe_include_demo(opts, assigns)
  end

  defp parse_opts(args) do
    {opts, _parsed} =
      OptionParser.parse!(args,
        strict: @switches,
        aliases: @aliases
      )

    merged_opts =
      @default_opts
      |> Keyword.merge(opts)
      |> Mix.SfcGenLive.put_context_app(opts[:context_app])

    merged_opts
  end

  defp validate_namespace!(namespace) do
    namespace_parts = Mix.SfcGenLive.split_name(namespace)

    cond do
      not Mix.SfcGenLive.valid_namespace?(namespace_parts) ->
        raise_with_help(
          "Expected the namespace, #{inspect(namespace)}, to be a valid module name"
        )

      true ->
        namespace_parts
    end
  end

  @spec raise_with_help(String.t()) :: no_return()
  defp raise_with_help(msg) do
    Mix.raise("""
    #{msg}

    mix sfc.gen.init takes

    - a `--[no-]demo` option, default true, that controls whether
    a demo component will be generated in the app.

    - a `--[no-]template` boolean option, default true, which specifies whether the
    demo component template will be in a `.sface` file or in a `~H` sigil in
    the component module

    - an optional `--namespace` option that is a relative path
    in `lib/my_app_web` where the demo card component will be created. The default
    value is `components`. The `--namespace` option is ignored if
    `--no-demo` is passed.


    For example:

         mix sfc.gen.init --namespace my_components

    will create `lib/my_app_web/my_components/card.ex` and `lib/my_app_web/my_components/card.sface`
    """)
  end

  defp maybe_include_demo(opts, assigns) do
    if opts[:demo] do
      paths = Mix.SfcGenLive.generator_paths()

      files = [
        {:eex, "card.ex", Path.join(assigns[:web_path], "#{assigns[:path]}.ex")}
      ]

      template_files = [
        {:eex, "card.sface", Path.join(assigns[:web_path], "#{assigns[:path]}.sface")}
      ]

      Mix.Phoenix.copy_from(paths, "priv/templates/sfc.gen.init", assigns, files)

      if opts[:template] do
        Mix.Phoenix.copy_from(paths, "priv/templates/sfc.gen.init", assigns, template_files)
      end
    end
  end

  def inject_in_formatter_exs() do
    file_path = ".formatter.exs"
    file = File.read!(file_path)

    unless Regex.match?(~r/import_deps:[^]]+:surface/, file) do
      Mix.shell().info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path)])
      file = String.replace(file, ~r/(import_deps:\s*\[[^]]+)\]/, "\\1, :surface]")
      File.write!(file_path, file)
    end
  end

  def inject_live_reload_config(web_path) do
    file_path = "config/dev.exs"
    file = File.read!(file_path)

    unless Regex.match?(~r/live_reload:[^]]+\(sface\)/s, file) do
      Mix.shell().info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path)])

      file =
        String.replace(
          file,
          ~r/(live_reload: .*\n)( *~r)([^]]+")(\s*)\]/s,
          "\\1\\2\\3,\n\\2\"#{web_path}/live/.*(sface)$\"\\4]"
        )

      File.write!(file_path, file)
    end
  end

  def inject_in_app_web_view_macro(web_module_path) do
    file = File.read!(web_module_path)

    file =
      Mix.SfcGenLive.insert_in_blocks_matching_fragment(
        file,
        "def view do",
        "import Surface",
        :quote,
        :first
      )

    File.write!(web_module_path, file)
  end
end
