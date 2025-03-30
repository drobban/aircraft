defmodule Aircraft do
  require Logger
  alias Aircraft.Calculator

  defmodule State do
    @type name :: String.t()
    @type status :: :takeoff | :inflight | :landed | :crash
    @type type :: :civilian | :military | :transport
    @type position :: float()
    @type speed_kmh :: integer()
    @type degrees :: float()

    @type t :: %__MODULE__{
            name: name(),
            status: status(),
            type: type(),
            pos_lat: position(),
            pos_lng: position(),
            destination_lat: position(),
            destination_lng: position(),
            speed: speed_kmh(),
            bearing: degrees()
          }

    @enforce_keys [
      :name,
      :type,
      :pos_lat,
      :pos_lng,
      :destination_lat,
      :destination_lng
    ]
    defstruct [
      :name,
      :type,
      :pos_lat,
      :pos_lng,
      :destination_lat,
      :destination_lng,
      bearing: 0.0,
      speed: 0,
      status: :takeoff
    ]
  end

  # aircrafts = for x <- 1..100, do: Aircraft.test(FlightControl, "MH#{x}", 51.12, 7.12, :rand.uniform(360), :rand.uniform(6_000_000))
  def spawn_random(control, supervisor, n_crafts) do
    _airports = [
      {"Hartsfield–Jackson Atlanta International Airport (ATL)", 33.6407, -84.4277},
      {"Los Angeles International Airport (LAX)", 33.9416, -118.4085},
      {"Chicago O'Hare International Airport (ORD)", 41.9742, -87.9073},
      {"Dallas/Fort Worth International Airport (DFW)", 32.8998, -97.0403},
      {"Denver International Airport (DEN)", 39.8561, -104.6737},
      {"John F. Kennedy International Airport (JFK)", 40.6413, -73.7781},
      {"San Francisco International Airport (SFO)", 37.6213, -122.3790},
      {"Seattle-Tacoma International Airport (SEA)", 47.4502, -122.3088},
      {"Miami International Airport (MIA)", 25.7959, -80.2870},
      {"Orlando International Airport (MCO)", 28.4312, -81.3081},
      {"London Heathrow Airport (LHR)", 51.4700, -0.4543},
      {"Paris Charles de Gaulle Airport (CDG)", 49.0097, 2.5479},
      {"Amsterdam Schiphol Airport (AMS)", 52.3105, 4.7683},
      {"Frankfurt Airport (FRA)", 50.0379, 8.5622},
      {"Tokyo Haneda Airport (HND)", 35.5494, 139.7798},
      {"Dubai International Airport (DXB)", 25.2532, 55.3657},
      {"Singapore Changi Airport (SIN)", 1.3644, 103.9915},
      {"Hong Kong International Airport (HKG)", 22.3080, 113.9185},
      {"Sydney Kingsford Smith Airport (SYD)", -33.9399, 151.1753},
      {"Toronto Pearson International Airport (YYZ)", 43.6777, -79.6248},
      {"Vancouver International Airport (YVR)", 49.1951, -123.1777},
      {"Mexico City International Airport (MEX)", 19.4361, -99.0719},
      {"São Paulo/Guarulhos–Governador André Franco Montoro Airport (GRU)", -23.4356, -46.4731},
      {"Cape Town International Airport (CPT)", -33.9710, 18.6021},
      {"Istanbul Airport (IST)", 41.2753, 28.7519},
      {"Beijing Capital International Airport (PEK)", 40.0799, 116.6031},
      {"Seoul Incheon International Airport (ICN)", 37.4602, 126.4407},
      {"Mumbai Chhatrapati Shivaji Maharaj International Airport (BOM)", 19.0896, 72.8656},
      {"Kuala Lumpur International Airport (KUL)", 2.7456, 101.7099},
      {"Bangkok Suvarnabhumi Airport (BKK)", 13.6894, 100.7501}
    ]

    airports = [
      {"London Heathrow Airport (LHR)", 51.4700, -0.4543},
      {"Paris Charles de Gaulle Airport (CDG)", 49.0097, 2.5479},
      {"Frankfurt Airport (FRA)", 50.0379, 8.5622},
      {"Amsterdam Airport Schiphol (AMS)", 52.3105, 4.7683},
      {"Madrid-Barajas Adolfo Suárez Airport (MAD)", 40.4983, -3.5676},
      {"Rome Fiumicino Airport (FCO)", 41.8003, 12.2389},
      {"Munich Airport (MUC)", 48.3537, 11.7861},
      {"Barcelona-El Prat Airport (BCN)", 41.2974, 2.0833},
      {"London Gatwick Airport (LGW)", 51.1537, -0.1821},
      {"Copenhagen Airport (CPH)", 55.6180, 12.6508},
      {"Vienna International Airport (VIE)", 48.1103, 16.5697},
      {"Dublin Airport (DUB)", 53.4213, -6.2701},
      {"Zurich Airport (ZRH)", 47.4647, 8.5492},
      {"Oslo Gardermoen Airport (OSL)", 60.1939, 11.1004},
      {"Stockholm Arlanda Airport (ARN)", 59.6498, 17.9238},
      {"Helsinki-Vantaa Airport (HEL)", 60.3172, 24.9633},
      {"Brussels Airport (BRU)", 50.9010, 4.4844},
      {"Lisbon Humberto Delgado Airport (LIS)", 38.7742, -9.1342},
      {"Moscow Sheremetyevo Airport (SVO)", 55.9728, 37.4146},
      {"Istanbul Airport (IST)", 41.2753, 28.7519}
    ]

    aircrafts =
      for x <- 1..n_crafts do
        # destination 
        {name, lat, lng} = Enum.at(airports, :rand.uniform(length(airports) - 1))
        # departure
        {_, dep_lat, dep_lng} =
          Enum.at(
            airports |> Enum.filter(fn {dep_name, _, _} -> dep_name != name end),
            :rand.uniform(length(airports) - 2)
          )

        # {dep_lat, dep_lng} =
        #   Calculator.calculate_new_position(
        #     dep_lat,
        #     dep_lng,
        #     :rand.uniform(360),
        #     :rand.uniform(1_000_000)
        #   )
        #
        # Time given in seconds
        etd = :rand.uniform(100) * 1_000

        factor = :rand.uniform(100) / 100
        speed = 800 * (1 + factor)

        Aircraft.supervised_round_trip(control, supervisor, "SU#{x}", lat, lng, dep_lat, dep_lng, speed, etd)
        # Aircraft.test(control, "MH#{x}", lat, lng, :rand.uniform(360), :rand.uniform(300_000))
      end

    {:ok, aircrafts}
  end


  def spawn_kalinin_random(control, supervisor, n_crafts) do
    airports = [
      {"London Heathrow Airport (LHR)", 51.4700, -0.4543},
      {"Paris Charles de Gaulle Airport (CDG)", 49.0097, 2.5479},
      {"Frankfurt Airport (FRA)", 50.0379, 8.5622},
      {"Amsterdam Airport Schiphol (AMS)", 52.3105, 4.7683},
      {"Madrid-Barajas Adolfo Suárez Airport (MAD)", 40.4983, -3.5676},
      {"Rome Fiumicino Airport (FCO)", 41.8003, 12.2389},
      {"Munich Airport (MUC)", 48.3537, 11.7861},
      {"Barcelona-El Prat Airport (BCN)", 41.2974, 2.0833},
      {"London Gatwick Airport (LGW)", 51.1537, -0.1821},
      {"Copenhagen Airport (CPH)", 55.6180, 12.6508},
      {"Vienna International Airport (VIE)", 48.1103, 16.5697},
      {"Dublin Airport (DUB)", 53.4213, -6.2701},
      {"Zurich Airport (ZRH)", 47.4647, 8.5492},
      {"Oslo Gardermoen Airport (OSL)", 60.1939, 11.1004},
      {"Stockholm Arlanda Airport (ARN)", 59.6498, 17.9238},
      {"Helsinki-Vantaa Airport (HEL)", 60.3172, 24.9633},
      {"Brussels Airport (BRU)", 50.9010, 4.4844},
      {"Lisbon Humberto Delgado Airport (LIS)", 38.7742, -9.1342},
      {"Moscow Sheremetyevo Airport (SVO)", 55.9728, 37.4146},
      {"Istanbul Airport (IST)", 41.2753, 28.7519}
    ]

    aircrafts =
      for x <- 1..n_crafts do
        # destination 
        {name, lat, lng} = Enum.at(airports, :rand.uniform(length(airports) - 1))
        # departure
        {_, _dep_lat, _dep_lng} =
          Enum.at(
            airports |> Enum.filter(fn {dep_name, _, _} -> dep_name != name end),
            :rand.uniform(length(airports) - 2)
          )

        # Time given in seconds
        etd = :rand.uniform(100) * 1_000

        factor = :rand.uniform(100) / 100
        speed = 800 * (1 + factor)

        Aircraft.supervised_round_trip(control, supervisor, "WZ#{x}", lat, lng, 54.318953467, 21.2486456, speed, etd)
      end

    {:ok, aircrafts}
  end




  def test(
        control,
        name \\ "MH417",
        dest_lat \\ 51.12,
        dest_lng \\ 7.12,
        approach \\ 180.0,
        distance \\ 50_000,
        etd \\ 10_000
      ) do
    # dest_lat = 51.12
    # dest_lng = 7.12

    {pos_lat, pos_lng} = Calculator.calculate_new_position(dest_lat, dest_lng, approach, distance)

    state = %Aircraft.State{
      name: name,
      type: :civilian,
      pos_lat: pos_lat,
      pos_lng: pos_lng,
      destination_lat: dest_lat,
      destination_lng: dest_lng,
      speed: 800,
      bearing: Calculator.calculate_bearing(pos_lat, pos_lng, dest_lat, dest_lng)
    }

    # This is an example on how to start an aircraft on the server.
    GenServer.start_link(Aircraft.Worker, %{
      initial_state: state,
      flight_control: control,
      etd: etd
    })
  end

  def round_trip(
        control,
        name \\ "MH417",
        dest_lat \\ 51.12,
        dest_lng \\ 7.12,
        dep_lat \\ 22.3080,
        dep_lng \\ 113.9185,
        speed \\ 800,
        etd \\ 10_000
      ) do
    # dest_lat = 51.12
    # dest_lng = 7.12

    state = %Aircraft.State{
      name: name,
      type: :civilian,
      pos_lat: dep_lat,
      pos_lng: dep_lng,
      destination_lat: dest_lat,
      destination_lng: dest_lng,
      speed: speed,
      bearing: Calculator.calculate_bearing(dep_lat, dep_lng, dest_lat, dest_lng)
    }

    Aircraft.Worker.start_link(%{
      initial_state: state,
      flight_control: control,
      etd: etd
    })
  end

  def supervised_round_trip(
        control,
        supervisor,
        name \\ "MH417",
        dest_lat \\ 51.12,
        dest_lng \\ 7.12,
        dep_lat \\ 22.3080,
        dep_lng \\ 113.9185,
        speed \\ 800,
        etd \\ 10_000
      ) do
    # dest_lat = 51.12
    # dest_lng = 7.12

    state = %Aircraft.State{
      name: name,
      type: :civilian,
      pos_lat: dep_lat,
      pos_lng: dep_lng,
      destination_lat: dest_lat,
      destination_lng: dest_lng,
      speed: speed,
      bearing: Calculator.calculate_bearing(dep_lat, dep_lng, dest_lat, dest_lng)
    }

    # Aircraft.Worker.start_link(%{
    #   initial_state: state,
    #   flight_control: control,
    #   etd: etd
    # })

    case :global.whereis_name(supervisor) do
      :undefined ->
        {:error, :supervisor_not_found}

      sup_pid ->
        DynamicSupervisor.start_child(
          sup_pid,
          {Aircraft.Worker, %{initial_state: state, flight_control: control, etd: etd}}
        )
    end
  end

  def get_state(name) do
    server = String.to_atom(name)
    GenServer.call(server, :get_state)
  end
end
