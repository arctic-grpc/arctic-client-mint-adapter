defmodule ArcticClientMintAdapter.MixProject do
  use Mix.Project

  def project do
    [
      app: :arctic_client_mint_adapter,
      version: "0.1.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mint, "~> 1.0"},
      {:castore, "~> 0.1.0"},
      {:arctic, github: "arctic-grpc/arctic"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
