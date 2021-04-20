defmodule Mix.SfcGenLive do
  @moduledoc false

  @doc """
  The paths to look for template files for generators.

  Defaults to checking the current app's `priv` directory,
  and falls back to Phoenix's `priv` directory.
  """
  def generator_paths do
    [".", :sfc_gen_live, :phoenix]
  end

  # this
  def put_context_app(opts, nil) do
    Keyword.put(opts, :context_app, Mix.Phoenix.context_app())
  end

  def put_context_app(opts, string) do
    Keyword.put(opts, :context_app, String.to_atom(string))
  end

  def valid_namespace?(name) when is_binary(name) do
    name
    |> split_name()
    |> valid_namespace?()
  end

  def valid_namespace?(namespace_parts) when is_list(namespace_parts) do
    Enum.all?(namespace_parts, &valid_module?/1)
  end

  def split_name(name) do
    name
    |> Phoenix.Naming.underscore()
    |> String.split("/", trim: true)
  end

  def inflect(namespace_parts, name_parts) do
    path = Enum.concat(namespace_parts, name_parts) |> Enum.join("/")
    base = Module.concat([Mix.Phoenix.base()])
    web_module = base |> Mix.Phoenix.web_module()
    scoped = path |> Phoenix.Naming.camelize()
    namespace_module = Module.concat(namespace_parts |> Enum.map(&Phoenix.Naming.camelize/1))
    module = Module.concat(web_module, scoped)
    alias = Module.concat([Module.split(module) |> List.last()])
    human = Enum.map(name_parts, &Phoenix.Naming.humanize/1) |> Enum.join(" ")

    [
      alias: alias,
      human: human,
      web_module: web_module,
      namespace_module: namespace_module,
      module: module,
      path: path
    ]
  end

  defp valid_module?(name) do
    Phoenix.Naming.camelize(name) =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/
  end
end
