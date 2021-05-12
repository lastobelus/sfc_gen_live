defmodule BlankComponent do
  @moduledoc """
  stuff
  """
  use Surface.Component
  import Something
  alias SomethingElse.{One, Two}

  def render(assigns) do
    ~H"""
    <h2>Howdy</h2>
    """
  end
end
