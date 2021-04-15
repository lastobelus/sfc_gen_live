defmodule Mix.Surface do
  @moduledoc false

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
    :path
  ]

  def validate_props(props) do
    Enum.reduce_while(props, :ok, fn {name, opts}, _acc ->
      case validate_prop(name, opts) do
        :ok ->
          {:cont, :ok}

        error ->
          {:halt, error}
      end
    end)
  end

  def validate_prop(_name, %{type: type}) when type in @types do
    :ok
  end

  def validate_prop(name, %{type: type}) do
    message = """
    invalid type #{type} for prop #{name}.
    Expected one of #{inspect(@types)}.
    Hint: Use :any if the type is not listed.\
    """

    {:error, message}
  end
end
