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

    test "it parses nested components and ignores html" do
      sface = """
      <Card>
        <Card.Header>
          <span>How dy</span>
          <Button>Click me</Button>
        </Card.Header>
        <Card.Footer>Lorem Ipsum</Card.Footer>
      </Card>
      """

      output = Design.parse(sface, 1, __ENV__)

      assert %DesignMeta{
               generators: %{
                 "card" => %Generator{generator: :component, name: "card"},
                 "card/header" => %Generator{generator: :component, name: "card/header"},
                 "card/footer" => %Generator{generator: :component, name: "card/footer"},
                 "button" => %Generator{generator: :component, name: "button"}
               }
             } = output
    end
  end
end
