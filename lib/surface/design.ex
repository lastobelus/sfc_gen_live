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
      case convert_node_to_generator(node_type(node), node, design_meta) do
        :ignore ->
          meta

        %Generator{name: name} = new_generator ->
          update_in(meta.generators[name], fn old_generator ->
            merge_generators(old_generator, new_generator)
          end)
      end
    end)
  end

  defp merge_generators(nil, generator), do: generator

  defp merge_generators(old_generator, new_generator) do
    # TODO
    new_generator
  end

  defp convert_node_to_generator(
         :component,
         {name, attributes, children, node_meta},
         design_meta
       ) do
    meta = Helpers.to_meta(node_meta, design_meta.compile_meta)
    mod = Helpers.actual_component_module!(name, meta.caller)
    meta = Map.merge(meta, %{module: mod, node_alias: name})
    name = Phoenix.Naming.underscore(mod)

    IO.inspect(mod, label: "85 mod")
    IO.inspect(name, label: "86 name")
    IO.inspect(meta, label: "87 meta")

    # TODO recurse here

    %Generator{generator: :component, name: name}
  end

  defp convert_node_to_generator(node_type, _node, _design_meta) do
    IO.puts("convert_node_to_generator: CANT PARSE #{node_type} yet")
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
end
