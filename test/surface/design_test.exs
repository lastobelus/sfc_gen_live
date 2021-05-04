defmodule Surface.DesignTest do
  @moduledoc false

  use ExUnit.Case

  alias Surface.Design
  alias Surface.Design.{DesignMeta, Generator}

  describe "Surface.Design" do
    test "it parses a component" do
      sface = "<Hello/>"
      output = Design.parse(sface, 1, __ENV__)

      assert %DesignMeta{
               generators: %{
                 "hello" => %Generator{generator: :component, name: "hello"}
               }
             } = output
    end
  end
end
