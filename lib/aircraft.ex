defmodule Aircraft do
  require Logger
  alias Aircraft.Calculator

  defmodule State do
    @type name :: String.t()
    @type status :: :takeoff | :inflight | :landed
    @type type :: :civilian | :military | :transport
    @type position :: float()
    @type speed_kmh :: integer()

    @type t :: %__MODULE__{
            name: name(),
            status: status(),
            type: type(),
            pos_lat: position(),
            pos_long: position(),
            destination_lat: position(),
            destination_long: position(),
            speed: speed_kmh()
          }

    @enforce_keys [
      :name,
      :type,
      :pos_lat,
      :pos_long,
      :destination_lat,
      :destination_long
    ]
    defstruct [
      :name,
      :type,
      :pos_lat,
      :pos_long,
      :destination_lat,
      :destination_long,
      speed: 0,
      status: :takeoff
    ]
  end

  def test() do
    dest_lat = 50.4119806
    dest_lng = 30.443292371766972

    {pos_lat, pos_lng} = Calculator.calculate_new_position(dest_lat, dest_lng, 180.0, 50_000)

    state = %Aircraft.State{
      name: "MH417",
      type: :civilian,
      pos_lat: pos_lat,
      pos_long: pos_lng,
      destination_lat: dest_lat,
      destination_long: dest_lng,
      speed: 800
    }

    GenServer.start_link(Aircraft.Worker, %{initial_state: state, flight_control: :testar})
  end
end
