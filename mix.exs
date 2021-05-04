defmodule SfcGenLive.MixProject do
  use Mix.Project

  @version "0.1.5"

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
      {:phoenix, git: "https://github.com/phoenixframework/phoenix.git", override: true},
      {:surface,
       git: "https://github.com/surface-ui/surface.git", orverride: true, branch: "surface-next"},
      # {:phx_new, "~> 1.5.8", only: [:dev, :test]},
      # RADAR: I don't think there is a way to specify this as a git dependency, since phx_new is a directory in phoenixframework/phoenix
      {:phx_new, path: "~/github/phoenix/installer", only: [:dev, :test]},
      {:ex_doc, "~> 0.20", only: :docs}
    ]
  end

  defp package do
    [
      maintainers: ["Michael Johnston"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/lastobelus/sfc_gen_live"}
    ]
  end
end
