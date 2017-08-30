defmodule Nerves.DHT.Test do
  use ExUnit.Case, async: false

  alias Nerves.DHT

  @dht_call_count "/tmp/dht_call_count"

  test "read ok" do
    set_sensor_response("55.1", "24.719", "0")
    assert {:ok, 55.1, 24.719} = DHT.read(:dht11, 17)
  end

  test "read errors code" do
    Enum.each(
      [{"-4", :gpio}, {"-3", :argument}, {"-2", :checksum}, {"-1", :timeout}],
      fn ({exit_status, exit_reason}) ->
        set_sensor_response("", "", exit_status)
        assert {:error, ^exit_reason} = DHT.read(:dht11, 17, 0)
      end
    )
  end
  
  test "read retry bad `retries` values" do
    set_sensor_response("", "", "-1")
    assert {:error, :timeout} = DHT.read(:dht11, 17, -1)
    check_call_counter(1)
  end

  test "read retry on transient errors" do
    retries = 2
    interval = 0

    set_sensor_response("", "", "-1")
    assert {:error, :timeout} = DHT.read(:dht11, 17, retries, interval)
    check_call_counter(retries + 1)

    set_sensor_response("", "", "-2")
    assert {:error, :checksum} = DHT.read(:dht11, 17, retries, interval)
    check_call_counter(retries + 1)
  end

  test "read retry interval" do
    interval = 200
    retries = 3

    set_sensor_response("", "", "-1")
    start_time = System.monotonic_time(:milliseconds)
    assert {:error, :timeout} = DHT.read(:dht11, 17, retries, interval)
    end_time  = System.monotonic_time(:milliseconds)
    
    elapsed_time = end_time - start_time
    
    assert elapsed_time >= (interval * (retries))
  end
  
  test "read stream" do
    interval = 0
    
    set_sensor_response("55.1", "24.719", "0")
    assert [{:ok, 55.1, 24.719}] = DHT.stream(:am2302, 17, interval) |> Enum.take(1)
  end
  
  test "read stream interval" do
    interval = 200
    take = 3
    
    set_sensor_response("55.1", "24.719", "0")
    expected = List.duplicate({:ok, 55.1, 24.719}, take)
    start_time = System.monotonic_time(:milliseconds)
    assert ^expected = DHT.stream(:am2302, 17, interval) |> Enum.take(take)
    end_time  = System.monotonic_time(:milliseconds)

    elapsed_time = end_time - start_time
    
    assert elapsed_time >= (interval * (take))
  end
  
  defp set_sensor_response(humidity, temperature, exit_status) do
    System.put_env("DHT_HUMIDITY", humidity)
    System.put_env("DHT_TEMPERATURE", temperature)
    System.put_env("DHT_EXIT", exit_status)
    File.rm(@dht_call_count)
  end

  defp check_call_counter(count) do
    data = File.read!(@dht_call_count)
    assert ^data = String.duplicate(".", count)
  end
end
