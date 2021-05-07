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

    test "it adds a required default slot to a component with non empty text content" do
      sface = """
      <Card>
        Lorem Ipsum
      </Card>
      """

      output = Design.parse(sface, 1, __ENV__)

      assert %DesignMeta{
               generators: %{
                 "card" => %Generator{
                   generator: :component,
                   name: "card",
                   slots: %{"default" => true}
                 }
               }
             } = output
    end

    test "it adds an optional default slot to a component with empty text content" do
      # there needs to be at least some whitespace, though, or the parser has no children.
      # i.e., the parser does not distinguish between <Bob></Bob> and <Bob/>
      sface = """
      <Card>
      </Card>
      """

      output = Design.parse(sface, 1, __ENV__)

      assert %DesignMeta{
               generators: %{
                 "card" => %Generator{
                   generator: :component,
                   name: "card",
                   slots: %{"default" => false}
                 }
               }
             } = output
    end

    test "it adds an optional default slot to a component with text content starting with 'optional`" do
      sface = """
      <Card>
        Optional text here
      </Card>
      """

      output = Design.parse(sface, 1, __ENV__)

      assert %DesignMeta{
               generators: %{
                 "card" => %Generator{
                   generator: :component,
                   name: "card",
                   slots: %{"default" => false}
                 }
               }
             } = output
    end

    test "it adds a required default slot to a component with html content" do
      sface = """
      <Card>
        <div>Lorem Ipsum</div>
      </Card>
      """

      output = Design.parse(sface, 1, __ENV__)

      assert %DesignMeta{
               generators: %{
                 "card" => %Generator{
                   generator: :component,
                   name: "card",
                   slots: %{"default" => true}
                 }
               }
             } = output
    end

    test "it adds props to components using the value as type" do
      sface = """
      <Card title={string}>
        Lorem Ipsum
      </Card>
      """

      output = Design.parse(sface, 1, __ENV__)

      assert %DesignMeta{
               generators: %{
                 "card" => %Generator{
                   generator: :component,
                   name: "card",
                   slots: %{"default" => true},
                   props: %{"title" => :string}
                 }
               }
             } = output
    end
  end
end
