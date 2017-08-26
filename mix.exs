defmodule DHT.Mixfile do
  use Mix.Project

  def project do
    [
      app: :nerves_dht,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      compilers: [:elixir_make] ++ Mix.compilers,
      deps: deps()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:elixir_make, "~> 0.4", runtime: false},
    ]
  end
end
