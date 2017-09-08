defmodule NervesDHT.Device do
  @moduledoc false

  defmodule Runner do
    @moduledoc false

    use GenServer

    defmodule State do
      @moduledoc false

      defstruct [:father, :fun, :timeout]
    end

    def start_link(father, fun, timeout) do
      state = %State{father: father, fun: fun, timeout: timeout}
      GenServer.start_link(__MODULE__, state)
    end

    @impl GenServer
    def handle_cast(:read, %State{father: father, fun: fun, timeout: timeout}=state) do
      task = Task.async(fun)
      case Task.yield(task, timeout) do
        {:ok, result} ->
          GenServer.cast(father, {:result, result})
        nil ->
          Task.shutdown(task)
          GenServer.cast(father, {:result, {:error, :timeout}})
      end
      {:noreply, state}
    end
  end

  use GenServer

  defmodule State do
    @moduledoc false
    defstruct [:runner, :callers_queue]
  end

  def start_link(name, fun, timeout \\ 4000) do
    GenServer.start_link(__MODULE__, [fun, timeout], name: name)
  end

  def read(ref, timeout \\ 5000) do
    GenServer.call(ref, :read, timeout)
  end

  @impl GenServer
  def init([fun, timeout]) do
    {:ok, runner} = Runner.start_link(self(), fun, timeout)
    {:ok, %State{runner: runner, callers_queue: []}}
  end

  @impl GenServer
  def handle_call(:read, from, %State{runner: runner, callers_queue: []}=state) do
    GenServer.cast(runner, :read)
    {:noreply, %State{state | callers_queue: [from]}}
  end

  @impl GenServer
  def handle_call(:read, from, %State{callers_queue: callers_queue}=state) do
    {:noreply, %State{state | callers_queue: [from | callers_queue]}}
  end

  @impl GenServer
  def handle_cast({:result, result}, %State{callers_queue: callers_queue}=state)
      when callers_queue != [] do
    notify(callers_queue, result)
    {:noreply, %State{state | callers_queue: []}}
  end

  defp notify(callers_queue, reply) do
    Enum.each(callers_queue, &(GenServer.reply(&1, reply)))
  end
end
