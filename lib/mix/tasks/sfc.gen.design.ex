defmodule Mix.Tasks.Sfc.Gen.Design do
  @moduledoc """
  Document Mix.Tasks.Sfc.Gen.Design here.
  """

  alias Surface.Design
  use Mix.Task

  @shortdoc ~s(Generate a set of Surface components from a "design" file in `.sface` format)

  # see https://hexdocs.pm/elixir/OptionParser.html#parse/2
  @switches [
    quiet: :boolean,
    template: :boolean,
    namespace: :string,
    dry_run: :boolean,
    output: :string,
    recursive: :boolean
  ]

  @default_opts [
    quiet: false,
    template: true,
    namespace: "components"
  ]

  @aliases [
    q: :quiet,
    t: :template,
    n: :namespace,
    d: :dry_run,
    o: :output,
    r: :recursive
  ]

  @doc false
  @impl true
  def run([version]) when version in ~w(-v --version) do
    Mix.SfcGenLive.print_version_banner(__MODULE__, quiet: false)
  end

  def run(args) do
    {opts, args} = parse_opts!(args)

    Mix.SfcGenLive.print_version_banner(__MODULE__, opts)

    IO.puts("opts: #{inspect(opts)}")
    IO.puts("args: #{inspect(args)}")

    {generator_opts, _other_opts} = Keyword.split(opts, [:template, :namespace])

    # to extract single options (ex: `@switches [name: :string]`)
    # `Keyword.get(opts, :name)`
    #
    # to extract array options (ex: `@switches [paths: [:string, :keep]]`)
    # `Keyword.get_values(:paths)`
    generators =
      args
      |> glob(opts)
      |> IO.inspect(label: "paths")
      |> Enum.reduce(%{}, fn path, generators ->
        Design.parse(
          File.read!(path),
          1,
          __ENV__,
          generators,
          path
        ).generators
      end)

    cond do
      opts[:dry_run] ->
        generators
        |> shell_cmds(generator_opts)
        |> IO.puts()

      opts[:output] ->
        cmds = shell_cmds(generators, generator_opts)
        File.write!(opts[:output], cmds)

      true ->
        generators
        |> run_generators(generator_opts)
    end
  end

  defp parse_opts!(args) do
    {opts, parsed} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)

    merged_opts = Keyword.merge(@default_opts, opts)

    {merged_opts, parsed}
  end

  defp glob(args, opts) do
    Enum.reduce_while(args, [], fn arg, paths ->
      arg =
        cond do
          opts[:recursive] -> arg <> "/**"
          true -> arg
        end

      case paths_from_arg(arg) do
        {:ok, glob} ->
          {:cont, paths ++ glob}

        {:error, err} ->
          {:halt, {:error, err, arg}}
      end
    end)
  end

  defp paths_from_arg(arg) do
    glob = Path.wildcard(arg)

    glob =
      cond do
        Enum.empty?(glob) ->
          Path.wildcard(arg <> ".sface")

        File.dir?(List.first(glob)) ->
          Path.wildcard(arg <> "/*.sface")

        true ->
          glob
      end

    cond do
      Enum.empty?(glob) ->
        {:error, :no_match_for_arg}

      true ->
        {:ok, glob}
    end
  end

  defp shell_cmds(generators, opts) do
    generators
    |> Enum.map(fn {_name, generator} ->
      to_shell_cmd(generator, opts)
    end)
    |> Enum.join("\n")
  end

  defp to_shell_cmd(%Design.Generator{} = generator, opts) do
    slots =
      generator.slots
      |> Enum.map(fn {name, required} ->
        "--slot #{name}#{required_slot_opt(required)}"
      end)

    props =
      generator.props
      |> Enum.map(fn {prop, type} ->
        "#{prop}:#{type}"
      end)

    for_slot =
      cond do
        slot = generator.slot ->
          ["--for-slot #{slot}"]

        true ->
          []
      end

    cmd =
      ["mix sfc.gen.#{generator.generator} #{generator.name}"] ++
        props ++
        slots ++
        for_slot ++
        to_shell_opts(opts)

    cmd
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp required_slot_opt(false), do: ""
  defp required_slot_opt(true), do: ":required"

  defp to_shell_opts(opts) do
    opts
    |> Enum.map(fn {opt, value} ->
      case value do
        true ->
          "--#{opt}"

        false ->
          "--no-#{opt}"

        _ ->
          "--#{opt} #{value}"
      end
    end)
  end

  defp run_generators(generators, opts) do
    IO.puts("run_generators...to be implemented. generators:\n#{inspect(generators)}")
    IO.puts("opts: #{inspect(opts)}")
  end
end
