Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Sfc.Gen.ComponentTest do
  @moduledoc false
  use ExUnit.Case
  import MixHelper

  alias Mix.Tasks.Sfc.Gen

  setup do
    Mix.Task.clear()
    :ok
  end

  test "invalid mix arguments", config do
    in_tmp_project(config.test, fn ->
      assert_raise Mix.Error,
                   ~r/Expected the component, "bob-stuff", to be a valid module name/,
                   fn ->
                     Gen.Component.run(~w(bob-stuff))
                   end

      assert_raise Mix.Error,
                   ~r/Expected the namespace, "bad-name", to be a valid module name/,
                   fn ->
                     Gen.Component.run(~w(bob --namespace bad-name))
                   end
    end)
  end

  test "generates component module in default namespace", config do
    in_tmp_project(config.test, fn ->
      # Gen.Component.run(~w(table/head size:string:required:values[small|medium|large]))
      Gen.Component.run(~w(
          table/head name:string:required
          columns:integer
          size:string:values[large,medium,small]:default[medium]
          --slot default:required
          --slot footer
          --slot panel[columns]
        ))

      assert_file("lib/sfc_gen_live_web/components/table/head.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.Components.Table.Head"
        assert file =~ "prop name, :string"
        assert file =~ "prop columns, :integer"
        assert file =~ "prop size, :string, default: \"medium\", values: ~w(large medium small)"
        assert file =~ "slot default, required: true"
        assert file =~ "slot footer"
        assert file =~ "slot panel, props: [:columns]"

        assert file =~ "<#slot/>"
        assert file =~ "<#slot name=\"footer\"/>"
        assert file =~ "<#slot name=\"panel\" :props={ columns: @columns }/>"
      end)

      assert_file("test/sfc_gen_live_web/components/table/head_test.exs", fn file ->
        # IO.puts("test file: #{file}")
        assert file =~ ~s(test "renders Table Head component" do)
      end)
    end)
  end

  test "typed slotable", config do
    in_tmp_project(config.test, fn ->
      # Gen.Component.run(~w(table/head size:string:required:values[small|medium|large]))
      Gen.Component.run(~w(
          card/header
          --slot default:required
          --for-slot header
        ))

      assert_file("lib/sfc_gen_live_web/components/card/header.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.Components.Card.Header"
        assert file =~ ~s(use Surface.Component, slot: "header")
        assert file =~ "slot default, required: true"
        assert file =~ "<#slot/>"
        assert file =~ ~r/<!--[^>]* typed slotable for slot `header`/
      end)
    end)
  end

  @tag :slow
  test "generated components compile and test passes", config do
    in_tmp_project(config.test, [:surface], fn ->
      # Gen.Component.run(~w(table/head size:string:required:values[small|medium|large]))
      Gen.Component.run(~w(
          table/head name:string:required
          columns:integer
          size:string:values[large,medium,small]:default[medium]
          --slot default:required
          --slot footer
          --slot panel[columns]
          --template
        ))

      System.cmd("mix", ~w(deps.get), stderr_to_stdout: true)
      # inspect_app_dir
      # head_component = File.read!("lib/sfc_gen_live_web/components/table/head.ex")
      # head_template = File.read!("lib/sfc_gen_live_web/components/table/head.sface")

      # IO.puts("head_component: \n#{head_component}\n\n")
      # IO.puts("head_template: \n#{head_template}\n\n")

      {mix_test_status, output} = run_mix_test(config.test)
      assert mix_test_status == :ok, "`mix test` failed: #{output}"
      IO.puts(output)
      assert output =~ ~S/TBD/
      # assert output =~ "TBD"
    end)
  end
end
