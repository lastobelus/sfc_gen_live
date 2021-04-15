defmodule Mix.Surface.Component.Props do
  @moduledoc false

  @prop_opt_names [
    {"required", "r"},
    {"default", "d"},
    {"values", "v"},
    {"accumulate", "a"}
  ]

  @prop_opt_value_regex ~r/[[\]]/

  def validate(props) do
    Mix.Surface.validate_props(props)
  end

  def parse(opts) do
    opts
    |> Enum.reduce(%{}, fn opt, props ->
      {name, prop} = parse_prop(opt)

      Map.put(props, name, prop |> Map.put_new(:opts, []))
    end)
  end

  defp parse_prop(prop) when is_binary(prop) do
    prop
    |> String.split(":", parts: 3)
    |> List.update_at(0, &normalize_name/1)
    |> parse_prop
  end

  defp parse_prop([name]) do
    {name, %{type: :string}}
  end

  defp parse_prop([name, type]) do
    {name, %{type: String.to_atom(type)}}
  end

  defp parse_prop([name, type, opts]) do
    opts =
      case parse_prop_opts(opts) do
        [] ->
          %{}

        list ->
          %{opts: ["" | list]}
      end

    {name,
     Map.merge(
       %{type: String.to_atom(type)},
       opts
     )}
  end

  defp parse_prop_opts(prop_opts) do
    prop_opts
    |> String.split(":", trim: true)
    |> extract_prop_opts()
    |> Enum.reverse()
  end

  defp extract_prop_opts(prop_opts) do
    Enum.reduce(@prop_opt_names, [], fn names, parsed_prop_opts ->
      case extract_prop_opt(names, prop_opts) do
        nil ->
          parsed_prop_opts

        content ->
          [content | parsed_prop_opts]
      end
    end)
  end

  defp extract_prop_opt(names, prop_opts) do
    prop_opts
    |> Enum.find(fn prop_opt ->
      Tuple.to_list(names)
      |> Enum.any?(fn name ->
        Regex.match?(~r/^#{name}\b/, prop_opt)
      end)
    end)
    |> prop_opt_content(elem(names, 0))
  end

  defp prop_opt_content(nil, _name), do: nil

  defp prop_opt_content(_rest, "required") do
    "required: true"
  end

  defp prop_opt_content(prop_opt, "default") do
    value =
      prop_opt
      |> String.split(@prop_opt_value_regex, trim: true)
      |> Enum.at(1)

    "default: \"#{value}\""
  end

  defp prop_opt_content(prop_opt, "values") do
    values =
      prop_opt
      |> String.split(@prop_opt_value_regex, trim: true)
      |> Enum.at(1)
      |> String.split(~r/[ ,]+/, trim: true)

    "values: ~w(#{Enum.join(values, " ")})"
  end

  defp prop_opt_content(_rest, "accumulate") do
    "accumulate: true"
  end

  defp normalize_name(name) do
    name |> String.replace(~r{[^a-zA-Z-_]}, "") |> String.to_atom()
  end
end
