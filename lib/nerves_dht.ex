defmodule NervesDHT do
  @moduledoc """
  Elixir library to read the DHT series of humidity and temperature sensors on a Raspberry Pi.
  """

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
  @typedoc "Successful reading humidity and temperature values"
  @type result :: {:ok, humidity :: float(), temperature :: float()} | {:error, reason}

  # executable name injection (tests use "dht_exe.sh" fake)
  @dht_exe Application.get_env(:nerves_dht, :dht_exe, "dht")

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
  def read(sensor, pin, retries \\ 3, delay \\ 2000)

  def read(sensor, pin, retries, delay) do
    result = dht_read(sensor, pin)

    case result do
      {:ok, humidity, temperature} ->
        {:ok, humidity, temperature}
      {:error, error} ->
        read_again(sensor, pin, retries, delay, error)
    end
  end

  @doc """
  Return a Stream of sensor readings.

  The reading `interval` defaults to 2 seconds.
  Interval is the wait period beetwen two consecutive read attempts.
  Since the device takes some X time to transmit the reading, the Stream
  will push data with a `period >= X+interval`.

  ## Examples

      iex> NervesDHT.stream(:am2302, 17) |> Enum.take(2)
      [{:ok, 55.1, 24.719}, {:ok, 55.12, 24.9}]

  """
  @spec stream(sensor, pin, interval) :: Enumerable.t
  def stream(sensor, pin, interval \\ 2000) do
    Stream.interval(interval)
    |> Stream.map(fn(_) -> read(sensor, pin, 0, 0) end)
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

  defp dht_read(sensor, pin) do
    cmd = Application.app_dir(:nerves_dht, Path.join("priv", @dht_exe))
    args = dht_cmd_args(sensor, pin)

    {result, exit_status} = System.cmd(cmd, args)

    if exit_status == 0 do
      [humidity_str, temperature_str] = String.split(result)

      {humidity, ""} = Float.parse(humidity_str)
      {temperature, ""} = Float.parse(temperature_str)

      {:ok, humidity, temperature}
    else
      {:error, dht_error_code_to_reason(exit_status)}
    end
  end

  defp dht_cmd_args(sensor, pin) do
    [
      case sensor do
        :dht11 -> "11"
        :dht22 -> "22"
        :am2302 -> "2302"
      end,
      to_string(pin)
    ]
  end

  # -1, -2, -3, -4
  defp dht_error_code_to_reason(255), do: :timeout
  defp dht_error_code_to_reason(254), do: :checksum
  defp dht_error_code_to_reason(253), do: :argument
  defp dht_error_code_to_reason(252), do: :gpio
end
