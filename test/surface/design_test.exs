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
      <section>
        <!-- utility components -->
        <Card>
          <Card.Header>
            <span>Howdy</span>
            <Button>Click me</Button>
          </Card.Header>
          <Card.Footer>Lorem Ipsum</Card.Footer>
        </Card>
      </section>
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

    test "it adds slots when it sees <:slot_name>" do
      sface = """
      <Card>
        <:header>Header text</:header>
        Body
        <:footer>
          Optional Footer Text
          <div>with html</div>
        </:footer>
      </Card>
      """

      output = Design.parse(sface, 1, __ENV__)

      assert %DesignMeta{
               generators: %{
                 "card" => %Generator{
                   generator: :component,
                   name: "card",
                   slots: %{"default" => true, "header" => true, "footer" => false}
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

    test "it adds props from content" do
      sface = """
      <Widget>
        Lorem Ipsum {@product|any}
      </Widget>
      """

      output = Design.parse(sface, 1, __ENV__)

      assert %DesignMeta{
               generators: %{
                 "widget" => %Generator{
                   generator: :component,
                   name: "widget",
                   slots: %{"default" => true},
                   props: %{"product" => :any}
                 }
               }
             } = output
    end

    test "it recognizes typed slots using slot=\"\"" do
      sface = """
      <Card>
        <Card.Header slot="header" other="string">
          Lorem Ipsum (some text not starting with optional makes the slot required)
          <span>Howdy</span>
          <Button>Click me</Button>
        </Card.Header>
        Lorem Ipsum
        <Card.Footer slot="footer"></Card.Footer>
      </Card>
      """

      output = Design.parse(sface, 1, __ENV__)

      assert %DesignMeta{
               generators: %{
                 "card" => %Generator{
                   generator: :component,
                   name: "card",
                   slots: %{"header" => true, "footer" => false}
                 },
                 "card/header" => %Generator{
                   generator: :component,
                   name: "card/header",
                   slot: "header"
                 },
                 "card/footer" => %Generator{
                   generator: :component,
                   name: "card/footer",
                   slot: "footer"
                 },
                 "button" => %Generator{generator: :component, name: "button"}
               }
             } = output
    end
  end
end
