defmodule Mix.Tasks.Sfc.Gen.Design do
  @moduledoc """
  Document Mix.Tasks.Sfc.Gen.Design here.
  """

  use Mix.Task

  @shortdoc "One-line description of Mix.Tasks.Sfc.Gen.Design here (used by mix help, required for task to show up)"

  @version "0.0.1"

  # customize colors of the CLI title banner for your task
  @cli_theme_bg 240
  @cli_theme_fg 250

  # see https://hexdocs.pm/elixir/OptionParser.html#parse/2
  @switches [quiet: :boolean]

  @default_opts [quiet: false]

  @doc false
  @impl true
  def run([version]) when version in ~w(-v --version) do
    print_version_banner(quiet: false)
  end

  def run(args) do
    {opts, args} = parse_opts!(args)

    print_version_banner(opts)

    IO.puts("opts: #{inspect(opts)}")
    IO.puts("args: #{inspect(args)}")

    # to extract single options (ex: `@switches [name: :string]`)
    # `Keyword.get(opts, :name)`
    #
    # to extract array options (ex: `@switches [paths: [:string, :keep]]`)
    # `Keyword.get_values(:paths)`
  end

  defp parse_opts!(args) do
    {opts, parsed} =
      OptionParser.parse!(args, strict: @switches, aliases: [q: :quiet])

    merged_opts = Keyword.merge(@default_opts, opts)

    {merged_opts, parsed}
  end

  defp print_version_banner(opts) do
    unless opts[:quiet] do
      text = theme(" Sfc.Gen.Design  v#{@version} ")
      IO.puts(text)
    end
  end

  defp theme(text) do
    IO.ANSI.color_background(@cli_theme_bg) <> IO.ANSI.color(@cli_theme_fg) <> text <> IO.ANSI.reset()
  end

end
