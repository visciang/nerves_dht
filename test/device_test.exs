defmodule Test.Device do
  use ExUnit.Case, async: false

  describe "NervesDHT.Device.read/2" do
    test "read ok" do
      device = :test_ok
      {:ok, _pid} = NervesDHT.Device.start_link(device, fn -> :ok! end)

      assert :ok! == NervesDHT.Device.read(device)
    end

    test "read timeout" do
      device = :test_timeout
      timeout = 200
      {:ok, _pid} = NervesDHT.Device.start_link(device, fn -> Process.sleep(timeout * 2) end, timeout)

      assert {:error, :timeout} == NervesDHT.Device.read(device)
    end

    @tag :capture_log
    test "read crash" do
      device = :test_crash
      {:ok, pid} = NervesDHT.Device.start_link(device, fn -> raise "crash" end)
      Process.unlink(pid)

      catch_exit do
        NervesDHT.Device.read(device)
      end

      refute Process.alive?(pid)
    end

    test "read parallel" do
      device = :test_parallel
      {:ok, _pid} = NervesDHT.Device.start_link(device,
        fn ->
          Process.sleep(400)  # :-(
          :rand.normal()
        end)

      task_1 = Task.async(fn -> NervesDHT.Device.read(device) end)
      task_2 = Task.async(fn -> NervesDHT.Device.read(device) end)
      x = Task.await(task_1)
      y = Task.await(task_2)
      assert x == y

      task_3 = Task.async(fn -> NervesDHT.Device.read(device) end)
      z = Task.await(task_3)
      assert z != x
    end
  end
end
