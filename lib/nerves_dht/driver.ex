defmodule NervesDHT.Driver do
  @moduledoc false

  # executable name injection (tests use "dht_exe.sh" fake)
  @dht_exe Application.get_env(:nerves_dht, :dht_exe, "dht")

  def dht_read(sensor, pin) do
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
