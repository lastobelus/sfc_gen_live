defmodule Mix.SfcGenLive do
  @moduledoc false

  @doc """
  The paths to look for template files for generators.

  Defaults to checking the current app's `priv` directory,
  and falls back to Phoenix's `priv` directory.
  """
  def generator_paths do
    [".", :sfc_gen_live, :phoenix]
  end
end
