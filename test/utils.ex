defmodule Test.Utils do
  require ExUnit.Assertions

  @dht_call_count "/tmp/dht_call_count"

  def set_sensor_response(humidity, temperature, exit_status) do
    System.put_env("DHT_HUMIDITY", humidity)
    System.put_env("DHT_TEMPERATURE", temperature)
    System.put_env("DHT_EXIT", exit_status)
    File.rm(@dht_call_count)
  end

  def check_call_counter(count) do
    data = File.read!(@dht_call_count)
    ExUnit.Assertions.assert ^data = String.duplicate(".", count)
  end
end
