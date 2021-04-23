Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Sfc.Gen.InitTest do
  use ExUnit.Case
  import MixHelper
  alias Mix.Tasks.Sfc.Gen

  setup do
    Mix.Task.clear()
    :ok
  end

  test "injects in .formatter.exs", config do
    in_generated_phoenix_live_project(config.test, fn ->
      Gen.Init.run(~w(
        --no-template
        --no-demo
      ))


      assert_file(".formatter.exs", fn file ->
        assert file =~ ":surface"
      end)
    end)
  end

  defp inspect_app_dir do
    IO.puts "----------------------------------------------"
    IO.puts("File.cwd!(): #{inspect(File.cwd!())}")
    IO.puts("File.ls!(): #{inspect(File.ls!())}")
    IO.puts "----------------------------------------------"
  end
end
