defmodule Mix.SfcGenLiveTest do
  @moduledoc false

  use ExUnit.Case

  alias Mix.SfcGenLive

  def load_component_fixture(name) do
    File.read!(Path.join("priv/fixtures/components", name, ".ex"))
  end

  describe "update_component_file/2" do
    test "adds slots to component file with no slots" do
    end

    test "adds slots to component file with slots" do
    end

    test "adds props to component file with no props" do
    end

    test "adds props to component file with props" do
    end
  end
end
