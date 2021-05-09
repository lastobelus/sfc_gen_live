Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Sfc.Gen.DesignTest do
  @moduledoc false

  use ExUnit.Case
  import MixHelper
  import ExUnit.CaptureIO

  alias Mix.Tasks.Sfc.Gen

  setup do
    Mix.Task.clear()
    :ok
  end

  describe "options" do
    test "it prints the version", config do
      in_tmp_project(config.test, fn ->
        assert capture_io(fn ->
                 Gen.Design.run(~w(-v))
               end) =~ "Sfc.Gen.Design  v0.1.5"
      end)
    end
  end

  # test "generates foo/bar", config do
  #   in_tmp_project(config.test, fn ->
  #     Gen.Design.run(~w(foo_bar -q))

  #     assert_file("lib/foo.bar.ex", fn file ->
  #       assert file =~ "defmodule Foo.Bar do"
  #     end)

  #   end)
  # end
end
