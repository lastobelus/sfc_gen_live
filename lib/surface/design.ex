defmodule Surface.Design do
  @moduledoc """
  `Surface.Design` contains functions for parsing a `.sface` file and emitting
  a series of `sfc.gen.component XXXX` commands that would generate all
  the components in that file.
  """

  # defstruct [:design, :generators]

  alias Surface.Compiler.{CompileMeta, Parser, ParseError, Helpers}
  alias Surface.Design.DesignMeta

  defmodule Generator do
    defstruct [:generator, :name, :props, :slots]
  end

  defmodule DesignMeta do
    defstruct [:compile_meta, :generators]

    @type t :: %__MODULE__{
            compile_meta: CompilerMeta,
            generators: %{String.t() => Generator}
          }
  end

  def parse(string, line_offset, caller, file \\ "nofile", opts \\ []) do
    compile_meta = %CompileMeta{
      line_offset: line_offset,
      file: file,
      caller: caller,
      checks: opts[:checks] || []
    }

    design_meta = %DesignMeta{
      compile_meta: compile_meta,
      generators: %{}
    }

    string
    |> Parser.parse()
    |> IO.inspect(label: "17 parser output")
    |> case do
      {:ok, nodes} ->
        nodes

      {:error, message, line} ->
        raise %ParseError{line: line + line_offset - 1, file: file, message: message}
    end
    |> to_generators(design_meta)
    |> IO.inspect(label: "output")
  end

  defp to_generators(nodes, design_meta) do
    nodes
    |> Enum.reduce(design_meta, fn node, meta ->
      extract_generators_from_node(node_type(node), node, meta)
    end)
  end

  defp merge_generators(nil, generator), do: generator
  defp merge_generators(old_generator, new_generator), do: new_generator

  defp add_generator(design_meta, new_generator) do
    update_in(design_meta.generators[new_generator.name], fn old_generator ->
      merge_generators(
        old_generator,
        new_generator
      )
    end)
  end

  defp extract_generators_from_node(
         :component,
         {name, attributes, children, node_meta},
         design_meta
       ) do
    meta = Helpers.to_meta(node_meta, design_meta.compile_meta)
    mod = Helpers.actual_component_module!(name, meta.caller)
    meta = Map.merge(meta, %{module: mod, node_alias: name})
    name = Phoenix.Naming.underscore(mod)

    IO.puts("------------extract_generators_from_node(component)-----------------")
    IO.inspect(mod, label: "85 mod")
    IO.inspect(name, label: "86 name")
    IO.inspect(meta, label: "87 meta")

    design_meta = to_generators(children, design_meta)

    add_generator(design_meta, %Generator{generator: :component, name: name})
  end

  defp extract_generators_from_node(:text, _text, design_meta), do: design_meta

  defp extract_generators_from_node(node_type, _node, design_meta) do
    IO.puts("extract_generators_from_node: CANT PARSE #{node_type} yet")
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

  # endregion [ copied-from-surface-compiler ]

  def inspect_generators(design_meta, msg) do
    IO.puts("msg\n#{inspect(design_meta.generators, pretty: true)}")
  end
end
