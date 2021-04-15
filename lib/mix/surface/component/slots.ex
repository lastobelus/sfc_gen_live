defmodule Mix.Surface.Component.Slots do
  @moduledoc false

  @slot_opt_regex ~r/[[\]]/

  # mix sfc.gen.component Hero section:string title:string --slot default --slot header --slot footer[section]:required --slot sidebar:required

  def parse(slots) do
    slots
    |> Keyword.get_values(:slot)
    |> Enum.map(&parse_slot/1)
  end

  defp parse_slot(slot) do
    [name_and_value | opts] = String.split(slot, ":", trim: true)

    [name | props] = String.split(name_and_value, @slot_opt_regex, trim: true)

    {slot_props, attr_props} = parse_slot_props(props)
    slot_opts = slot_props ++ parse_slot_opts(opts)

    slot_opts =
      case(length(slot_opts)) do
        0 -> slot_opts
        _ -> ["" | slot_opts]
      end

    %{
      name: name,
      opts: slot_opts,
      attr_name: attr_name(name),
      attr_props: attr_props
    }
  end

  defp parse_slot_opts([]), do: []

  defp parse_slot_opts(opts) do
    opts
    |> Enum.reduce([], fn opt, parsed_opts ->
      case parse_slot_opt(opt) do
        nil -> parsed_opts
        content -> [content | parsed_opts]
      end
    end)
  end

  defp parse_slot_opt(opt) do
    Enum.find_value([&parse_required/1, &parse_as/1], fn opt_func ->
      case opt_func.(opt) do
        nil ->
          false

        content ->
          content
      end
    end)
  end

  defp attr_name("default"), do: ""
  defp attr_name(name), do: " name=\"#{name}\""

  defp parse_slot_props([]), do: {[], ""}

  defp parse_slot_props([props]) do
    props = String.split(props, ~r/[, ]/)

    props_opts = Enum.map(props, fn prop -> ":#{prop}" end)
    props_attrs = Enum.map(props, fn prop -> "#{prop}: @#{prop}" end)

    {
      ["props: [#{Enum.join(props_opts, ", ")}]"],
      " :props={{#{Enum.join(props_attrs, ", ")}}}"
    }
  end

  defp parse_required("required"), do: "required: true"
  defp parse_required(_opt), do: nil

  defp parse_as(prop) do
    case String.split(prop, @slot_opt_regex, trim: true) do
      ["as" | at_opt] -> "as: :#{hd(at_opt)}"
      _ -> nil
    end
  end
end
