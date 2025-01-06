defmodule Aircraft.Worker do
  require Logger
  alias Aircraft.Calculator
  alias Aircraft.State
  use GenServer

  @tick 10_000
  @kmh_to_ms 3.6

  def start_link(
        %{initial_state: %Aircraft.State{}, flight_control: _flight_controller} =
          state
      ) do
    GenServer.start_link(__MODULE__, state, name: String.to_atom(state.initial_state.name))
  end

  @impl true
  def init(%{initial_state: %State{} = aircraft, flight_control: controller, etd: etd} = _state) do
    initial_state = %{
      aircraft: aircraft,
      timeout_ref: nil,
      flight_control: controller,
      etd: etd
    }

    {:ok, initial_state, {:continue, :setup}}
  end

  @impl true
  def handle_continue(:setup, %{aircraft: %Aircraft.State{} = aircraft} = state) do
    etd = if state.etd < @tick, do: @tick, else: state.etd
    timeout_ref = Process.send_after(self(), :tick, etd)
    aircraft = %Aircraft.State{aircraft | status: :inflight}
    {:noreply, state |> Map.put(:timeout_ref, timeout_ref) |> Map.put(:aircraft, aircraft)}
  end

  @impl true
  def handle_call(:get_state, from, state) do
    Logger.debug("Got call from #{inspect(from)}")
    {:reply, state, state}
  end

  @impl true
  def handle_info(:tick, %{aircraft: %Aircraft.State{} = aircraft} = state) do
    kmh = aircraft.speed
    m = @tick / 1000 * (kmh / @kmh_to_ms)

    bearing =
      Calculator.calculate_bearing(
        aircraft.pos_lat,
        aircraft.pos_lng,
        aircraft.destination_lat,
        aircraft.destination_lng
      )

    ping =
      ping_traffic_control(state.flight_control, state.aircraft.pos_lat, state.aircraft.pos_lng)

    case ping do
      {:ok, topics} ->
        for topic <- topics do
          broadcast(state.flight_control, topic, state)
        end

      nil ->
        Logger.debug("No client stations in reach")
    end

    {pos_lat, pos_lng} =
      Calculator.calculate_new_position(aircraft.pos_lat, aircraft.pos_lng, bearing, m)

    {timeout_ref, aircraft} =
      case arrived?(
             pos_lat,
             pos_lng,
             aircraft.destination_lat,
             aircraft.destination_lng,
             @tick,
             aircraft.speed
           ) do
        true ->
          aircraft_state = %State{
            aircraft
            | pos_lat: aircraft.destination_lat,
              pos_lng: aircraft.destination_lng,
              status: :landed
          }

          {:ok, topics} = ping

          for topic <- topics do
            broadcast(state.flight_control, topic, %{aircraft: aircraft_state})
            Logger.debug("Broadcast to #{topic}!")
          end

          {nil, aircraft_state}

        false ->
          timeout_ref = Process.send_after(self(), :tick, @tick)
          {timeout_ref, %State{aircraft | pos_lat: pos_lat, pos_lng: pos_lng}}
      end

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

  # Controller is a module that we assume implements a list_topics fn.
  # We could perhaps go bananas with behaviour
  defp ping_traffic_control(controller, lat, lng) do
    if function_exported?(controller, :return_topics, 2) do
      {:ok, controller.return_topics(lat, lng)}
    else
      Logger.debug("List topics not implemented in controller module #{inspect(controller)}")
      nil
    end
  end

  defp broadcast(controller, topic, state) do
    if function_exported?(controller, :broadcast, 2) do
      {:ok, controller.broadcast(topic, state.aircraft)}
    else
      Logger.debug("Broadcast not available")
      nil
    end
  end
end
