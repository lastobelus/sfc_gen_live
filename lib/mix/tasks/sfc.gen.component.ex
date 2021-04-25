defmodule Mix.Tasks.Sfc.Gen.Component do
  @moduledoc """
  Generates a Surface component.
  """
  use Mix.Task

  alias Mix.Surface.Component.{Props, Slots}

  @switches [template: :boolean, namespace: :string, slot: [:string, :keep], context_app: :string]
  @default_opts [template: false, namespace: "components"]
  @doc false
  def run(args) do
    {opts, slots, name, props} = parse_opts(args)

    {namespace_parts, name_parts} = validate_args!(name, opts[:namespace])

    props = props |> Props.parse() |> validate_props!()
    # |> validate_slots!()
    slots = slots |> Slots.parse()

    assigns =
      Mix.SfcGenLive.inflect(namespace_parts, name_parts)
      |> Keyword.put(:props, props)
      |> Keyword.put(:template, opts[:template])
      |> Keyword.put(:slots, slots)

    paths = Mix.SfcGenLive.generator_paths()

    files = [
      {:eex, "component.ex", Path.join(assigns[:web_path], "#{assigns[:path]}.ex")}
    ]

    template_files = [
      {:eex, "component.sface", Path.join(assigns[:web_path], "#{assigns[:path]}.sface")}
    ]

    Mix.Phoenix.copy_from(paths, "priv/templates/sfc.gen.component", assigns, files)

    if opts[:template] do
      Mix.Phoenix.copy_from(paths, "priv/templates/sfc.gen.component", assigns, template_files)
    end

    # Generator.copy_template("priv/templates/sfc.gen.component/component.ex", dest, assigns)
  end

  # def build_component(args) do
  # end

  defp validate_args!(name, namespace) do
    {namespace_parts, name_parts} = normalized_component_name(name, namespace)

    cond do
      not Mix.SfcGenLive.valid_namespace?(name_parts) ->
        raise_with_help("Expected the component, #{inspect(name)}, to be a valid module name")

      not Mix.SfcGenLive.valid_namespace?(namespace_parts) ->
        raise_with_help(
          "Expected the namespace, #{inspect(namespace)}, to be a valid module name"
        )

      true ->
        {namespace_parts, name_parts}
    end
  end

  defp validate_props!(props) do
    case Props.validate(props) do
      :ok ->
        props

      {:error, msg} ->
        raise_with_help(msg)
    end
  end

  @spec raise_with_help(String.t()) :: no_return()
  defp raise_with_help(msg) do
    Mix.raise("""
    #{msg}

    mix sfc.gen.component expects a component module name, and an optional `namespace`
    option that is a valid module name.
    The component name and/or namespace can also be supplied in 'underscore' form.
    For example:

         mix sfc.gen.component Button
         mix sfc.gen.component table/head
         mix sfc.gen.component table/head --namespace reporting

    ## Props

    Props are specified with `name:type:opts` where type is a valid Surface prop
    type, and opts are one or more of `required`, `default`, `values`, `accumulate`.

    Short-forms can be used for the props:

    r == required
    d == default
    a == accumulate
    v == values


    If default is specified, it should be followed with the value in brackets.
    If values is specified, it should be followed with a pipe-delimited list
    of values in brackets.

        mix sfc.gen.component Button rounded:boolean color:string:default[gray]
        mix sfc.gen.component Button size:string:values[large,medium,small]

    ## Slots

    Slots can be specified with `--slot` switches.
    For example:

        mix sfc.gen.component Hero section:string \
          --slot default:required \
          --slot header \
          --slot footer[section]

    will add

        slot :default, required: true
        slot :header
        slot :footer, values: [:section]


    ## Template or Sigil

    By default, sfc.gen.component creates a `my_component.sface` file.
    If you pass `--no-template` it will instead include a `render/1` function with
    the template in a `~H` sigil.
    """)
  end

  defp parse_opts(args) do
    {opts_and_slots, parsed} =
      OptionParser.parse!(args, strict: @switches, aliases: [t: :template])

    {slots, opts} = Keyword.split(opts_and_slots, [:slot])

    merged_opts =
      @default_opts
      |> Keyword.merge(opts)
      |> Mix.SfcGenLive.put_context_app(opts[:context_app])

    [name | props] = parsed
    {merged_opts, slots, name, props}
  end

  @spec normalized_component_name(String.t(), String.t()) :: {[String.t()], [String.t()]}
  defp normalized_component_name(name, namespace) do
    namespace_parts = Mix.SfcGenLive.split_name(namespace)
    name_parts = Mix.SfcGenLive.split_name(name) |> strip_namespace(namespace_parts)
    {namespace_parts, name_parts}
  end

  defp strip_namespace(name_parts, namespace_parts) do
    case List.starts_with?(name_parts, namespace_parts) do
      true ->
        Enum.slice(name_parts, length(namespace_parts)..-1)

      false ->
        name_parts
    end
  end
end
