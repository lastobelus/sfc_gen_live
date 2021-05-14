defmodule ComponentWithMultilineProps do
  @moduledoc """
  stuff
  """
  use Surface.Component
  import Something
  alias SomethingElse.{One, Two}

  @doc "a name"
  prop name, :string

  @doc """
  Colour of the button
  """
  prop colour,
    :string,
    default: "black",
    values: ButtonUtils.available_colours()

  prop breaks, :string, values: ["bob", "mary"]

  @doc "property opts"
  prop opts, :keyword, default: []

  def render(assigns) do
    ~H"""
    <h2>Howdy</h2>
    """
  end
end
