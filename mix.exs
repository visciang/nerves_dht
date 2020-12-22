defmodule NervesDHT.Mixfile do
  use Mix.Project

  def project do
    [
      app: :nerves_dht,
      version: "1.2.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.github": :test
      ],
      compilers: [:elixir_make] ++ Mix.compilers(),
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    if Mix.env() == :test do
      [extra_applications: [:logger]]
    else
      []
    end
  end

  defp deps do
    [
      {:nerves_sad, git: "https://github.com/visciang/nerves_sad.git", tag: "1.1.1"},
      {:elixir_make, "~> 0.4", runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.13", only: :test},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/visciang/nerves_dht",
      extras: ["README.md"]
    ]
  end
end
