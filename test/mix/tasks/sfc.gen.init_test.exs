Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Sfc.Gen.InitTest do
  use ExUnit.Case
  import MixHelper
  alias Mix.Tasks.Sfc.Gen

  setup do
    Mix.Task.clear()
    :ok
  end

  test "injects in .formatter.exs, config.dev.exs", config do
    in_generated_phoenix_live_project(config.test, fn ->
      Gen.Init.run(~w(
        --no-template
        --no-demo
      ))

      assert_file(".formatter.exs", fn file ->
        assert file =~ ":surface"
      end)

      assert_file("config/dev.exs", fn file ->
        assert file =~ ~S|~r"lib/sfc_gen_live_web/live/.*(sface)$"|
      end)

      assert_file("lib/sfc_gen_live_web.ex", fn file ->
        %{"view_quote" => view_quote} =
          Regex.named_captures(
            ~r/def view do\s+quote do\s+(?<view_quote>.*?(?=end))/ms,
            file
          )

        assert view_quote =~ "import Surface"
      end)
    end)
  end

  test "creates single-file card component with --demo, --no-template", config do
    in_generated_phoenix_live_project(config.test, fn ->
      Gen.Init.run(~w(
        --demo
        --no-template
      ))

      assert_file("lib/sfc_gen_live_web/components/card.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.Components.Card do"
        assert file =~ ~S(<div class={{ @class }}>)
      end)

      refute_file("lib/sfc_gen_live_web/components/card.sface")
    end)
  end

  test "creates card component with template file with --demo, --template", config do
    in_generated_phoenix_live_project(config.test, fn ->
      Gen.Init.run(~w(
        --demo
        --template
      ))

      assert_file("lib/sfc_gen_live_web/components/card.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.Components.Card do"
        refute file =~ ~S(<div class={{ @class }}>)
      end)

      assert_file("lib/sfc_gen_live_web/components/card.sface", fn file ->
        assert file =~ ~S(<div class={{ @class }}>)
      end)
    end)
  end

  defp inspect_app_dir(also \\ nil) do
    IO.puts("----------------------------------------------")
    IO.puts("File.cwd!(): #{inspect(File.cwd!())}")
    IO.puts("File.ls!(): #{inspect(File.ls!())}")

    if also do
      IO.puts("File.ls!(#{also}): #{inspect(File.ls!(also))}")
    end

    IO.puts("----------------------------------------------")
  end
end
