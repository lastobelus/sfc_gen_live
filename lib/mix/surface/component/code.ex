defmodule Mix.Surface.Component.Code do
  @moduledoc """
  Document Mix.Surface.Component.Code here.
  """

  def update_component_file!(component_file, opts) do
    component = File.read!(component_file)

    [head, props_section, middle, slots_section, body] = split_component(component)

    # IO.puts("head: #{inspect(head)}")
    # IO.puts("props_section: #{inspect(props_section)}")
    # IO.puts("middle: #{inspect(middle)}")
    # IO.puts("slots_section: #{inspect(slots_section)}")
    # IO.puts("body: #{inspect(body)}")

    props_section =
      props_section
      |> add_props(opts[:props])

    slots_section =
      slots_section
      |> add_slots(opts[:slots])

    updated_code =
      Enum.join([
        head,
        "\n\n",
        props_section,
        "\n\n",
        middle,
        slots_section,
        "\n\n",
        body,
        "\n"
      ])

    # IO.puts("updated_code:\n#{updated_code}")

    File.write!(
      component_file,
      updated_code
    )
  end

  def add_props(code, props) do
    Enum.reduce(props, code, &add_prop/2)
  end

  def add_slots(code, slots) do
    Enum.reduce(slots, code, &add_slot/2)
  end

  def prop_regex(prop_name), do: ~r/^\s*prop +#{prop_name}\b.*$/m
  def slot_regex(slot_name), do: ~r/^\s*slot +#{slot_name}\b.*$/m

  def add_slot(slot, slots) do
    if Regex.match?(slot_regex(slot.name), slots) do
      slots
    else
      add_part(
        slots,
        ~s|  slot #{slot.name}#{Enum.join(slot.opts, ", ")}|
      )
    end
  end

  def add_prop({name, prop}, props) do
    if Regex.match?(prop_regex(name), props) do
      props
    else
      add_part(
        props,
        ~s|  prop #{name}, #{prop.type}#{Enum.join(prop.opts, ", ")}|
      )
    end
  end

  def add_part("", template), do: template
  def add_part(section, template), do: section <> "\n\n" <> template

  def split_component(component) do
    [head, body] = split_head_body(component)
    [head_rest, props, body] = split_at_props(body)
    [middle, slots, body] = split_at_slots(body)

    [head <> head_rest, props, middle, slots, body]
    |> Enum.map(&String.trim_trailing/1)
    |> Enum.map(fn s -> String.trim_leading(s, "\n") end)
  end

  def split_at_defmodule(component) do
    regex = ~r/^\s*defmodule +.*\n/m
    parts = split_at_last(component, regex)

    case length(parts) do
      1 -> {:error, :no_module_defined}
      2 -> parts
    end
  end

  def split_at_moduledoc(component) do
    split_at_last(
      component,
      ~r/^\s*@moduledoc *""".*\n(?:^\s*(?:(?!""").)*\n)*\s+"""\s*/m,
      true
    )
  end

  def split_at_imports(component) do
    split_at_last(
      component,
      ~r/^\s*(?:use|alias|import) +.*\n/m,
      true
    )
  end

  def split_head_body(component) do
    [mod, body] = split_at_defmodule(component)
    [moddoc, body] = split_at_moduledoc(body)
    [imports, body] = split_at_imports(body)
    [mod <> moddoc <> imports, body]
  end

  def split_at_props(component), do: split_at_section(component, "prop")
  def split_at_slots(component), do: split_at_section(component, "slot")

  def split_at_section(component, keyword) do
    regex = ~r/
      # match optional doc
      (?:
        ^\ *@doc\ +
        # which might be single quoted or heredoc quoted
        (?:
          (?:"[^"]*"[\n])
            |
          (?:"""[\n]
            (?:^\ *(?:(?!""").)*[\n])* # zero or more lines that dont start with heredoc quotes
            \ *"""
          )
        )\s*
      ){0,1}
      # followed by a prop
      ^\ *#{keyword}\ +
        \w+
        (?:,\s*[^,\n]+)* # which might be broken up into multiple lines
        \ *[\n]?
    /msx

    split_first_to_last(
      component,
      regex
    )
  end

  def slots(component) do
    split_at_last(
      component,
      ~r/^\s*slot +\w+(?:,[^,]+)*\s*\n/ms,
      true
    )
  end

  # Regex.scan(~r/^\s*@moduledoc *""".*\n(?:^\s*(?:(?!""").)*\n)*\s+"""\s*/m, c, return: :index)
  # ~r/^\s(?:use|alias|import).*\n/m

  @spec split_at_last(binary, Regex.t(), any) :: [binary, ...]
  def split_at_last(c, regex, always \\ false) do
    ix =
      regex
      |> Regex.scan(c, return: :index)
      |> List.last()

    case ix do
      nil ->
        if always do
          ["", c]
        else
          [c]
        end

      [{ix, len}] ->
        String.split_at(c, ix + len) |> Tuple.to_list()
    end
  end

  def split_first_to_last(component, regex) do
    indices =
      regex
      |> Regex.scan(component, return: :index)

    case indices do
      [] ->
        ["", "", component]

      [[{0, len}]] ->
        [
          "",
          String.slice(component, 0..len),
          String.slice(component, (len + 1)..-1)
        ]

      [[{first, len}]] ->
        last = first + len

        [
          String.slice(component, 0..(first - 1)),
          String.slice(component, first..last),
          String.slice(component, (last + 1)..-1)
        ]

      [[{first_ix, _}] | rest] ->
        [{last, len}] = List.last(rest)
        last_ix = last + len

        [
          String.slice(component, 0..(first_ix - 1)),
          String.slice(component, first_ix..last_ix),
          String.slice(component, (last_ix + 1)..-1)
        ]
    end
  end

  defp blank?(str_or_nil),
    do: "" == str_or_nil |> to_string() |> String.trim()

  defp add_blank_unless_empty?(str) do
    cond do
      blank?(str) -> str
      true -> str <> "\n"
    end
  end
end
