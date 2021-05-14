Code.require_file("../../../mix_helper.exs", __DIR__)

defmodule Mix.Surface.Component.CodeTest do
  @moduledoc false

  use ExUnit.Case
  import MixHelper

  alias Mix.Surface.Component.Code
  alias Mix.Surface.Component.{Props, Slots}

  def with_props(opts, props_args) do
    Keyword.put(opts, :props, Props.parse(props_args))
  end

  def with_slots(opts, slots_args) do
    Keyword.put(opts, :slots, Slots.parse(slots_args))
  end

  def fixture_path(name), do: Path.join(File.cwd!(), "priv/fixtures/components/#{name}")

  def with_fixture(test, fixture, func) do
    path = fixture_path(fixture)

    in_tmp(test, fn ->
      File.cp!(path, fixture)
      func.()
    end)
  end

  describe "update_component_file/2" do
    test "adds props and slots to existing blank component", config do
      opts =
        []
        |> with_props(["colour:string", "title:string"])
        |> with_slots(slot: "default:required", slot: "footer", slot: "header:required")

      fixture_name = "blank_component.ex"

      with_fixture(config.test, fixture_name, fn ->
        Code.update_component_file!(fixture_name, opts)
        updated_component = File.read!(fixture_name)

        assert updated_component =~
                 """
                 defmodule BlankComponent do
                   @moduledoc \"""
                   stuff
                   \"""
                   use Surface.Component
                   import Something
                   alias SomethingElse.{One, Two}

                   prop colour, string

                   prop title, string

                   slot default, required: true

                   slot footer

                   slot header, required: true

                   def render(assigns) do
                     ~H\"""
                     <h2>Howdy</h2>
                     \"""
                   end
                 end
                 """
      end)
    end

    test "adds props and slots to existing component with props", config do
      opts =
        []
        |> with_props(["colour:string", "title:string"])
        |> with_slots(slot: "default:required", slot: "footer", slot: "header:required")

      fixture_name = "component_with_multiline_props.ex"

      with_fixture(config.test, fixture_name, fn ->
        Code.update_component_file!(fixture_name, opts)
        updated_component = File.read!(fixture_name)

        assert updated_component =~
                 """
                 defmodule ComponentWithMultilineProps do
                   @moduledoc \"""
                   stuff
                   \"""
                   use Surface.Component
                   import Something
                   alias SomethingElse.{One, Two}

                   @doc "a name"
                   prop name, :string

                   @doc \"""
                   Colour of the button
                   \"""
                   prop colour,
                     :string,
                     default: "black",
                     values: ButtonUtils.available_colours()

                   prop breaks, :string, values: ["bob", "mary"]

                   @doc "property opts"
                   prop opts, :keyword, default: []

                   prop title, string

                   slot default, required: true

                   slot footer

                   slot header, required: true

                   def render(assigns) do
                     ~H\"""
                     <h2>Howdy</h2>
                     \"""
                   end
                 end
                 """
      end)
    end

    test "adds props and slots to component with slots but doesn't change required", config do
      opts =
        []
        |> with_props(["colour:string", "title:string"])
        |> with_slots(slot: "default:required", slot: "footer", slot: "header:required")

      fixture_name = "component_with_slots.ex"

      with_fixture(config.test, fixture_name, fn ->
        Code.update_component_file!(fixture_name, opts)
        updated_component = File.read!(fixture_name)

        assert updated_component =~
                 """
                 defmodule ComponentWithSlots do
                   @moduledoc \"""
                   stuff
                   \"""
                   use Surface.Component
                   import Something
                   alias SomethingElse.{One, Two}

                   prop colour, string

                   prop title, string

                   slot default

                   @doc "required header"
                   slot header, required: true

                   slot footer

                   def render(assigns) do
                     ~H\"""
                     <h2>Howdy</h2>
                     \"""
                   end
                 end
                 """
      end)
    end
  end
end
