Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Sfc.Gen.InitTest do
  use ExUnit.Case
  import MixHelper
  alias Mix.Tasks.Sfc.Gen

  setup do
    Mix.Task.clear()
    :ok
  end
end
