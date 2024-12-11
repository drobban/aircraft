defmodule Aircraft do
  require Logger

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
    state = %Aircraft.State{
      name: "MH417",
      type: :civilian,
      pos_lat: 51.2312313,
      pos_long: 8.21212121,
      destination_lat: 51.2412313,
      destination_long: 8.21212121
    }

    Logger.debug(inspect(state))

    # Example usage:
    current_lat = 45.0
    current_lng = -93.0
    # Moving east
    bearing = 360.0
    # 1 meter
    distance = 1.0

    {new_lat, new_lng} =
      new_position =
      Calculator.calculate_new_position(current_lat, current_lng, bearing, distance)

    Logger.debug(inspect({current_lat, current_lng}))
    Logger.debug(inspect(new_position))

    # lets fact check
    bearing = Calculator.calculate_bearing(current_lat, current_lng, new_lat, new_lng)
    distance = Calculator.calculate_distance(current_lat, current_lng, new_lat, new_lng)
    Logger.debug(inspect(bearing))
    Logger.debug(inspect(distance))
  end
end
