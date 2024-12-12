defmodule Aircraft.Worker do
  require Logger
  alias Aircraft.State
  use GenServer

  @tick 10_000

  @impl true
  def init(%State{} = state) do
    initial_state = %{state: state, timeout_ref: nil}
    {:ok, initial_state, {:continue, :setup}}
  end

  @impl true
  def handle_continue(:setup, state) do
    timeout_ref = Process.send_after(self(), :tick, @tick)
    aircraft_state = %Aircraft.State{Map.get(state, :state) | status: :inflight}
    {:noreply, state |> Map.put(:timeout_ref, timeout_ref) |> Map.put(:state, aircraft_state)}
  end

  @impl true
  def handle_info(:tick, state) do
    timeout_ref = Process.send_after(self(), :tick, @tick)

    Logger.debug("State #{inspect state[:state]}")
    {:noreply, state |> Map.put(:timeout_ref, timeout_ref)}
  end
end
