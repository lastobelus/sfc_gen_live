defmodule SfcGenLive.MixProject do
  use Mix.Project

  @version "0.1.3"

  def project do
    [
      app: :sfc_gen_live,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "The equivalent of `phx.gen.live` for Surface & Phoenix 1.5",
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.5.8"},
      {:phx_new, "~> 1.5.8", only: [:dev, :test]},
      {:ex_doc, "~> 0.20", only: :docs}
    ]
  end

  defp package do
    [
      maintainers: ["Michael Johnston"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/lastobelus/surface_gen_live"}
    ]
  end
end
