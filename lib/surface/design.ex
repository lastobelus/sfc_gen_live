defmodule Surface.Design do
  @moduledoc """
  `Surface.Design` contains functions for parsing a `.sface` file and emitting
  a series of `sfc.gen.component XXXX` commands that would generate all
  the components in that file.
  """

  # defstruct [:design, :generators]

  alias Surface.Compiler.{CompileMeta, Parser, ParseError}
  alias Surface.Design.DesignMeta

  defmodule Generator do
    defstruct [:generator, :name, :slot, props: %{}, slots: %{}]
  end

  defmodule DesignMeta do
    defstruct [:compile_meta, :parent, :generators]

    @type t :: %__MODULE__{
            compile_meta: CompilerMeta,
            generators: %{String.t() => Generator}
          }
  end

  def parse(string, line, caller, generators \\ %{}, file \\ "nofile", opts \\ [])

  def parse(string, line, caller, generators, file, opts) do
    compile_meta = %CompileMeta{
      line: line,
      file: file,
      caller: caller,
      checks: opts[:checks] || []
    }

    design_meta = %DesignMeta{
      compile_meta: compile_meta,
      generators: generators,
      parent: []
    }

    string
    |> Parser.parse!()
    # |> IO.inspect(label: "parser output")
    |> to_generators(design_meta)

    # |> IO.inspect(label: "output")
  end

  defp to_generators(%DesignMeta{} = design_meta, nodes), do: to_generators(nodes, design_meta)

  defp to_generators(nodes, %DesignMeta{} = design_meta) do
    nodes
    |> Enum.reduce(design_meta, fn node, meta ->
      extract_generators_from_node(node_type(node), node, meta)
    end)
  end

  defp add_generator(design_meta, new_generator) do
    update_in(design_meta.generators[new_generator.name], fn old_generator ->
      merge_generators(old_generator, new_generator)
    end)
  end

  defp merge_generators(nil, new_generator), do: new_generator

  defp merge_generators(old_generator, new_generator) do
    %Generator{
      generator: new_generator.generator,
      name: new_generator.name,
      slot: new_generator.slot,
      slots: Map.merge(old_generator.slots, new_generator.slots),
      props: Map.merge(old_generator.props, new_generator.slots)
    }
  end

  defp extract_generators_from_node(
         :component,
         {name, attributes, children, _node_meta},
         design_meta
       ) do
    name = Phoenix.Naming.underscore(name)

    {attributes, slot} = split_typed_slot?(attributes)

    design_meta
    |> add_slot(slot, required_content?(children))
    |> push_parent(name)
    |> add_generator(%Generator{generator: :component, name: name, slot: slot})
    |> add_props(attributes)
    |> to_generators(children)
    |> pop_parent()
  end

  defp extract_generators_from_node(
         :template,
         {name, attributes, children, _node_meta},
         design_meta
       ) do
    slot = get_slot_name(name, attributes)

    required = required_content?(children)

    design_meta
    |> add_slot(to_string(slot), required)
  end

  defp extract_generators_from_node(:text, text, design_meta) do
    trimmed = text |> String.downcase() |> String.trim()

    required = not (String.length(trimmed) == 0 or String.starts_with?(trimmed, "optional"))
    add_slot(design_meta, "default", required)
  end

  defp extract_generators_from_node(:tag, {_name, _attributes, children, _node_meta}, design_meta) do
    design_meta
    |> add_slot("default", true)
    |> to_generators(children)
  end

  defp extract_generators_from_node(:interpolation, {_, text, _node_meta}, design_meta) do
    app_prop_from_interpolation(design_meta, text)
  end

  defp extract_generators_from_node(_node_type, _node, design_meta) do
    # IO.puts("extract_generators_from_node: CANT PARSE #{node_type} yet")
    design_meta
  end

  # region [ copied-from-surface-compiler ]
  @void_elements [
    "area",
    "base",
    "br",
    "col",
    "command",
    "embed",
    "hr",
    "img",
    "input",
    "keygen",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr"
  ]

  defp node_type({"#template", _, _, _}), do: :template
  defp node_type({"#slot", _, _, _}), do: :slot
  defp node_type({"template", _, _, _}), do: :template
  defp node_type({":" <> _, _, _, _}), do: :template
  defp node_type({"slot", _, _, _}), do: :slot
  defp node_type({"#" <> _, _, _, _}), do: :macro_component
  defp node_type({<<first, _::binary>>, _, _, _}) when first in ?A..?Z, do: :component
  defp node_type({name, _, _, _}) when name in @void_elements, do: :void_tag
  defp node_type({_, _, _, _}), do: :tag
  defp node_type({:interpolation, _, _}), do: :interpolation
  defp node_type({:comment, _}), do: :comment
  defp node_type(_), do: :text

  defp attribute_value(attributes, attr_name, default) do
    Enum.find_value(attributes, default, fn {name, value, _} ->
      if name == attr_name do
        String.to_atom(value)
      end
    end)
  end

  defp get_slot_name("template", attributes), do: attribute_value(attributes, "slot", :default)
  defp get_slot_name("#template", attributes), do: attribute_value(attributes, "slot", :default)
  defp get_slot_name(":" <> name, _), do: String.to_atom(name)

  # endregion [ copied-from-surface-compiler ]

  # region [ copied-from-surface-api]
  @types [
    :any,
    :css_class,
    :list,
    :event,
    :boolean,
    :string,
    :time,
    :date,
    :datetime,
    :naive_datetime,
    :number,
    :integer,
    :decimal,
    :map,
    :fun,
    :atom,
    :module,
    :changeset,
    :form,
    :keyword,
    :struct,
    :tuple,
    :pid,
    :port,
    :reference,
    :bitstring,
    :range,
    :mapset,
    :regex,
    :uri,
    :path,
    # Private
    :generator,
    :context_put,
    :context_get
  ]

  defp validate_type(_func, _name, type) when type in @types do
    :ok
  end

  defp validate_type(func, name, type) do
    message = """
    invalid type #{Macro.to_string(type)} for #{func} #{name}.
    Expected one of #{inspect(@types)}.
    Hint: Use :any if the type is not listed.\
    """

    {:error, message}
  end

  # endregion [ copied-from-surface-api]
  def inspect_generators(design_meta, msg) do
    IO.puts("#{msg}\n#{inspect(design_meta.generators, pretty: true)}")
  end

  defp push_parent(design_meta, parent) do
    %DesignMeta{design_meta | parent: [parent | design_meta.parent]}
  end

  defp pop_parent(design_meta) do
    [_popped | parent] = design_meta.parent
    %DesignMeta{design_meta | parent: parent}
  end

  defp parent(design_meta) do
    List.first(design_meta.parent)
  end

  defp required_content?([text | _rest]) when is_binary(text) do
    required_content?(text)
  end

  defp required_content?(text) when is_binary(text) do
    text
    |> String.trim()
    |> String.downcase()
    |> String.starts_with?("optional")
    |> Kernel.not()
  end

  defp required_content?(_) do
    false
  end

  defp split_typed_slot?([]), do: {[], nil}

  defp split_typed_slot?(attributes) do
    # TODO: validate only one "slot" attributes
    {attributes, slot_attributes} =
      Enum.split_with(attributes, fn attr ->
        elem(attr, 0) != "slot"
      end)

    slot =
      case slot_attributes do
        [] -> nil
        [{"slot", name, _} | _] -> name
      end

    {attributes, slot}
  end

  defp add_slot(design_meta, nil, _required), do: design_meta

  defp add_slot(design_meta, [{"slot", name, _meta}], required) do
    add_slot(design_meta, name, required)
  end

  defp add_slot(design_meta, name, required) when is_binary(name) do
    case parent(design_meta) do
      nil ->
        design_meta

      parent_name ->
        update_in(design_meta.generators[parent_name].slots, fn slots ->
          case required do
            true ->
              Map.put(slots, name, true)

            false ->
              Map.put_new(slots, name, false)
          end
        end)
    end
  end

  defp add_props(design_meta, []), do: design_meta

  defp add_props(design_meta, attributes) do
    attributes
    |> Enum.reduce(design_meta, &add_prop_from_attribute/2)
  end

  defp add_prop_from_attribute({name, value, _attr_meta}, design_meta) do
    generator_name = parent(design_meta)

    update_in(design_meta.generators[generator_name].props, fn props ->
      Map.put(props, name, prop_opts_from_attribute_value(value))
    end)
  end

  defp prop_opts_from_attribute_value({:attribute_expr, type, _meta}) do
    # TODO validation/error handling
    prop_opts_from_attribute_value(type)
  end

  defp prop_opts_from_attribute_value(type) when is_binary(type) do
    String.to_existing_atom(type)
  end

  defp app_prop_from_interpolation(design_meta, value) do
    cond do
      String.starts_with?(value, "@") ->
        value = String.slice(value, 1..-1)
        [prop, type | _rest] = String.split(value <> "|string", "|")

        generator_name = parent(design_meta)

        update_in(design_meta.generators[generator_name].props, fn props ->
          Map.put(props, prop, String.to_existing_atom(type))
        end)

      true ->
        design_meta
    end
  end
end
