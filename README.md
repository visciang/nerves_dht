# Nerves DHT

[![Build Status](https://travis-ci.org/visciang/nerves_dht.svg?branch=master)](https://travis-ci.org/visciang/nerves_dht) [![Docs](https://img.shields.io/badge/docs-latest-green.svg)](https://visciang.github.io/nerves_dht/readme.html) [![Coverage Status](https://coveralls.io/repos/github/visciang/nerves_dht/badge.svg?branch=master)](https://coveralls.io/github/visciang/nerves_dht?branch=master)

Elixir library to read the DHT series of humidity and temperature sensors on a Raspberry Pi.
The library is supposed to be included in a [nerves project](http://nerves-project.org/).

If you want to build your project directly on a Raspberry (not in a crosscompiling nerves project)
just export `MIX_TARGET` environment variable to you mix build.
Valid values for `MIX_TARGET` are `rpi`, `rp2`, `rp3`.

* Supported sensors: DHT11, DHT22, AM2302
* Supported boards: Raspberry 1, 2, 3

**Note**: the library has no external dependencies and use a C executable to read the sensors data.

## Installation

The package can be installed by adding `nerves_dht` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nerves_dht, git: "https://github.com/visciang/nerves_dht.git", tag: "xxx"}
  ]
end
```

## Usage

```elixir
iex> NervesDHT.read(:am2302, 17)
{:ok, 55.1, 24.719}

iex> NervesDHT.stream(:am2302, 17) |> Enum.take(2)
[{:ok, 55.1, 24.719}, {:ok, 55.12, 24.9}]
```

If you plan to read concurrently from the sensor, add `NervesDHT` to your application supervisor tree:

```elixir
children = [
  {NervesDHT, [name: :my_sensor, sensor: :am2302, pin: 17]},
  ...
]
Supervisor.start_link(children, strategy: :one_for_one)
```

and read with:

```elixir
NervesDHT.device_read(:my_sensor)
NervesDHT.device_stream(:my_sensor)
```
