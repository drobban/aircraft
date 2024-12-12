defmodule Aircraft.Worker do
  require Logger
  alias Aircraft.Calculator
  alias Aircraft.State
  use GenServer

  @tick 10_000
  @kmh_to_ms 3.6

  @impl true
  def init(%State{} = state) do
    initial_state = %{aircraft: state, timeout_ref: nil}
    {:ok, initial_state, {:continue, :setup}}
  end

  @impl true
  def handle_continue(:setup, %{aircraft: %Aircraft.State{} = aircraft} = state) do
    timeout_ref = Process.send_after(self(), :tick, @tick)
    aircraft = %Aircraft.State{aircraft | status: :inflight}
    {:noreply, state |> Map.put(:timeout_ref, timeout_ref) |> Map.put(:aircraft, aircraft)}
  end

  @impl true
  def handle_info(:tick, %{aircraft: %Aircraft.State{} = aircraft} = state) do
    kmh = aircraft.speed
    m = @tick / 1000 * (kmh / @kmh_to_ms)

    bearing =
      Calculator.calculate_bearing(
        aircraft.pos_lat,
        aircraft.pos_long,
        aircraft.destination_lat,
        aircraft.destination_long
      )

    Logger.debug("Is this activated hot! #{bearing}")

    {pos_lat, pos_lng} =
      Calculator.calculate_new_position(aircraft.pos_lat, aircraft.pos_long, bearing, m)

    {timeout_ref, aircraft} =
      case arrived?(
             pos_lat,
             pos_lng,
             aircraft.destination_lat,
             aircraft.destination_long,
             @tick,
             aircraft.speed
           ) do
        true ->
          {nil,
           %State{
             aircraft
             | pos_lat: aircraft.destination_lat,
               pos_long: aircraft.destination_long,
               status: :landed
           }}

        false ->
          timeout_ref = Process.send_after(self(), :tick, @tick)
          {timeout_ref, %State{aircraft | pos_lat: pos_lat, pos_long: pos_lng}}
      end

    Logger.debug("State #{inspect(aircraft)}")
    {:noreply, state |> Map.put(:timeout_ref, timeout_ref) |> Map.put(:aircraft, aircraft)}
  end

  ## Helpers 
  # arrived? if distance < speed / kmh_to_ms * @tick / 1000 then we have arrived.
  # otherwise our plane will keep missing its target and move back and forth.
  defp arrived?(lat1, lng1, lat2, lng2, tick_in_ms, speed_kmh) do
    m = tick_in_ms / 1000 * (speed_kmh / @kmh_to_ms)
    distance = Calculator.calculate_distance(lat1, lng1, lat2, lng2)

    distance < m
  end
end
