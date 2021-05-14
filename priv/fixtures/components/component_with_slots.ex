defmodule ComponentWithSlots do
  @moduledoc """
  stuff
  """
  use Surface.Component
  import Something
  alias SomethingElse.{One, Two}

  slot default

  @doc "required header"
  slot header, required: true

  def render(assigns) do
    ~H"""
    <h2>Howdy</h2>
    """
  end
end
