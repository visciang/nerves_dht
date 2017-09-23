defmodule NervesDHT do
  @moduledoc """
  Elixir library to read the DHT series of humidity and temperature sensors on a Raspberry Pi.

  The library expose direct access to the sensors via `read/4` and `stream/3`.

  If your application has multiple processes reading the same sensor concurrently you should
  add `NervesDHT` under your supervisor (see `child_spec/1`).
  It ensures that only one read operation at the time is executed.
  In case of multiple sources asking for a read while the operation is in progress, they will
  get the result of the ongoing read.
  """

  @typedoc "Device identifier"
  @type device_id :: atom
  @typedoc "Sensor model"
  @type sensor :: :dht11 | :dht22 | :am2302
  @typedoc "GPIO pin (using BCM numbering)"
  @type pin :: 0..31
  @typedoc "Number of retries on transient errors"
  @type retries :: non_neg_integer
  @typedoc "Delay between reading retries in [ms]"
  @type delay :: non_neg_integer
  @typedoc "Streaming period in [ms]"
  @type interval :: non_neg_integer
  @typedoc "Error reason"
  @type reason :: :timeout | :checksum | :argument | :gpio
  @typedoc "Reading result"
  @type result :: {:ok, humidity :: float(), temperature :: float()} | {:error, reason}

  @retries 3
  @delay 2000

  @doc """
  Read DHT sensor values.

  Read from the specified `sensor` type (DHT11, DHT22, or AM2302) on
  specified `pin` and return humidity (as a floating point value in
  percent) and temperature (as a floating point value in Celsius) as
  a tuple `{:ok, humidity, temperature}`.

  Note that because the sensor requires strict timing to read and Linux is
  not a real time OS, a result is not guaranteed to be returned! The function
  will attempt to read multiple times (up to the specified max `retries`+1) until
  a good reading can be found. If a good reading cannot be found after the
  amount of retries the function returns {:error, :timeout}. The delay between
  retries is by default 2 seconds, but can be overridden (also note the DHT
  sensor cannot be read faster than about once every 2 seconds).

  ## Examples

      iex> NervesDHT.read(:am2302, 17)
      {:ok, 55.1, 24.719}

  """
  @spec read(sensor, pin, retries, delay) :: result
  def read(sensor, pin, retries \\ @retries, delay \\ @delay)

  def read(sensor, pin, retries, delay) do
    result = NervesDHT.Driver.dht_read(sensor, pin)

    case result do
      {:ok, humidity, temperature} ->
        {:ok, humidity, temperature}
      {:error, error} ->
        read_again(sensor, pin, retries, delay, error)
    end
  end

  @doc """
  Return a Stream of sensor readings.

  `interval` is the wait period beetwen two consecutive read attempts and
  defaults to 2 seconds. Since the device takes some `x` time to transmit
  the reading, the Stream will push data with a `period >= (interval + x)`.

  ## Examples

      iex> NervesDHT.stream(:am2302, 17) |> Enum.take(2)
      [{:ok, 55.1, 24.719}, {:ok, 55.12, 24.9}]

  """
  @spec stream(sensor, pin, interval) :: Enumerable.t
  def stream(sensor, pin, interval \\ @delay) do
    Stream.interval(interval)
    |> Stream.map(fn(_) -> read(sensor, pin, 0, 0) end)
  end

  @doc """
  Return the child specification to put the a named device under your supervisor tree.
  The device can be used to read concurrently from the sensor.

  Add to you supervisor:

  ```elixir
  children = [
    {NervesDHT, [name: :my_sensor, sensor: :am2302, pin: 17]},
    ...
  ]
  Supervisor.start_link(children, strategy: :one_for_one)
  ```

  Read from the named `:my_sensor` device:

  ```elixir
  NervesDHT.device_read(:my_sensor)
  ```
  """
  @spec child_spec([name: device_id, sensor: sensor, pin: pin]) :: Supervisor.child_spec
  def child_spec([name: name, sensor: sensor, pin: pin]) do
    fun = fn -> __MODULE__.read(sensor, pin) end
    timeout = @retries * @delay
    %{
      id: "#{__MODULE__}_#{sensor}_#{pin}",
      start: {NervesDHT.Device, :start_link, [name, fun, timeout]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }
  end

  @doc """
  Read DHT sensor values from the named device `device_id`.
  The underlying `read/4` operation will apply the default `retries`, `delay` strategy.

  See `child_spec/1`, `read/4`.
  """
  @spec device_read(device_id) :: result
  def device_read(device_id) do
    NervesDHT.Device.read(device_id, (@retries + 1) * @delay)
  end

  @doc """
  Return a Stream of sensor readings from the named device `device_id`.

  See `child_spec/1`, stream/3.
  """
  @spec device_stream(device_id, interval) :: Enumerable.t
  def device_stream(device_id, interval \\ @delay) do
    Stream.interval(interval)
    |> Stream.map(fn(_) -> device_read(device_id) end)
  end

  defp read_again(_sensor, _pin, retries, _delay, error) when retries <= 0 do
    {:error, error}
  end

  defp read_again(sensor, pin, retries, delay, error) do
    if error == :timeout or error == :checksum do
      # transient errors ->  pause and retry
      Process.sleep(delay)
      read(sensor, pin, retries - 1, delay)
    else
      {:error, error}
    end
  end
end
