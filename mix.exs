defmodule ElixirPopularity.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_popularity,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ElixirPopularity.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2.0"},
      {:httpoison, "~> 1.7.0"},
      {:broadway, "~> 0.6.0"},
      {:broadway_rabbitmq, "~> 0.6.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:gen_rmq, "~> 2.6.0"}
    ]
  end

  defp aliases do
    [setup: ["deps.get", "ecto.create", "ecto.migrate"]]
  end
end
