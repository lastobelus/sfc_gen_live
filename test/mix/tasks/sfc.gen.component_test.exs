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

        assert file =~ "<slot/>"
        assert file =~ "<slot name=\"footer\"/>"
        assert file =~ "<slot name=\"panel\" :props={{columns: @columns}}/>"
      end)
    end)
  end
end
