defmodule Test.DirectAccess do
  use ExUnit.Case, async: false

  alias NervesDHT, as: DHT
  alias Test.Utils

  describe "NervesDHT.read/4" do
    test "read ok" do
      Utils.set_sensor_response("55.1", "24.719", "0")
      assert {:ok, 55.1, 24.719} == DHT.read(:dht11, 17)
    end

    test "read errors code" do
      Enum.each(
        [{"252", :gpio}, {"253", :argument}, {"254", :checksum}, {"255", :timeout}],
        fn {exit_status, exit_reason} ->
          Utils.set_sensor_response("", "", exit_status)
          assert {:error, exit_reason} == DHT.read(:dht11, 17, 0)
        end
      )
    end

    test "read retry bad `retries` values" do
      Utils.set_sensor_response("", "", "255")
      assert {:error, :timeout} == DHT.read(:dht11, 17, -1)
      assert 1 == Utils.call_counter()
    end

    test "read retry on transient errors" do
      retries = 2
      interval = 0

      Utils.set_sensor_response("", "", "255")
      assert {:error, :timeout} == DHT.read(:dht11, 17, retries, interval)
      assert retries + 1 == Utils.call_counter()

      Utils.set_sensor_response("", "", "254")
      assert {:error, :checksum} == DHT.read(:dht11, 17, retries, interval)
      assert retries + 1 == Utils.call_counter()
    end

    test "read retry interval" do
      interval = 200
      retries = 3

      Utils.set_sensor_response("", "", "255")
      start_time = System.monotonic_time(:millisecond)
      assert {:error, :timeout} == DHT.read(:dht11, 17, retries, interval)
      end_time = System.monotonic_time(:millisecond)

      elapsed_time = end_time - start_time

      assert elapsed_time >= interval * retries
    end
  end

  describe "NervesDHT.stream/3" do
    test "read stream" do
      interval = 0

      Utils.set_sensor_response("55.1", "24.719", "0")
      assert [{:ok, 55.1, 24.719}] == DHT.stream(:am2302, 17, interval) |> Enum.take(1)
    end

    test "read stream interval" do
      interval = 200
      take = 3

      Utils.set_sensor_response("55.1", "24.719", "0")
      expected = List.duplicate({:ok, 55.1, 24.719}, take)
      start_time = System.monotonic_time(:millisecond)
      assert expected == DHT.stream(:am2302, 17, interval) |> Enum.take(take)
      end_time = System.monotonic_time(:millisecond)

      elapsed_time = end_time - start_time

      assert elapsed_time >= interval * take
    end
  end
end

defmodule Test.Supervised do
  use ExUnit.Case, async: false

  alias NervesDHT, as: DHT
  alias Test.Utils

  setup do
    opts = [name: :test_sensor, sensor: :am2302, pin: 17]
    {:ok, _pid} = start_supervised({NervesDHT, opts})

    :ok
  end

  test "device_read" do
    Utils.set_sensor_response("55.1", "24.719", "0")
    assert {:ok, 55.1, 24.719} == DHT.device_read(:test_sensor)
  end

  test "device_stream" do
    Utils.set_sensor_response("40.1", "20.1", "0")
    assert [{:ok, 40.1, 20.1}] == DHT.device_stream(:test_sensor) |> Enum.take(1)
  end
end
