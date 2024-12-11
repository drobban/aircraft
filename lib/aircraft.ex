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
      :destination_long,
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
    state = %Aircraft.State{name: "MH417", type: :civiliann, pos_lat: 51.2312313, pos_long: 8.21212121, destination_lat: 51.2412313, destination_long: 8.21212121}
    Logger.debug(inspect state)
  end
end
