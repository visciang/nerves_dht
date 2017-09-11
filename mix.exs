defmodule NervesDHT.Mixfile do
  use Mix.Project

  def project do
    [
      app: :nerves_dht,
      version: "1.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      compilers: [:elixir_make] ++ Mix.compilers,
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    if Mix.env == :test do
      [extra_applications: [:logger]]
    else
      []
    end
  end

  defp deps do
    [
      {:elixir_make, "~> 0.4", runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/visciang/nerves_dht",
      extras: ["README.md"],
    ]
  end
end
