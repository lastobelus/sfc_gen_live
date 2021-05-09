defmodule Mix.Tasks.Sfc.Gen.Design do
  @moduledoc """
  Document Mix.Tasks.Sfc.Gen.Design here.
  """

  use Mix.Task

  @shortdoc ~s(Generate a set of Surface components from a "design" file in `.sface` format)

  @version "0.0.1"

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

    # to extract single options (ex: `@switches [name: :string]`)
    # `Keyword.get(opts, :name)`
    #
    # to extract array options (ex: `@switches [paths: [:string, :keep]]`)
    # `Keyword.get_values(:paths)`
    paths = glob(args, opts)
    IO.puts("paths: #{inspect(paths)}")
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
end
