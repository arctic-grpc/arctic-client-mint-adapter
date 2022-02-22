defmodule ArcticClientMintAdapter.ResponseDispatcher do
  @moduledoc """
  Keeps record of in flight requests and dispatches the response

  When new HTTP reference is stored, it swapns a ResponseStream
  GenServer and monitor it.
  It tracks:
    * HTTP Stream reference
    * The caller's pid(in format of GenServer.from)
    * Monitor's reference of ResponseStream
  Keeps record of in flight requests and their caller's pid


  TODO: This module is doing to much, rather the monitor happens outside
  one idea could be that this is a GenServer of it's own. How ever send
  should not happen in this genserver as it has overhead.
  """
  defstruct [:in_flight_requests, :monitor_form_refs]

  alias ArcticClientMintAdapter.ResponseStream
  @type t :: %__MODULE__{in_flight_requests: map, monitor_form_refs: map}

  @spec new :: t
  def new do
    %__MODULE__{in_flight_requests: %{}, monitor_form_refs: %{}}
  end

  @spec put(t, reference, GenServer.form(), map) :: {:ok, t, pid}
  def put(state, ref, from, response_stream_struct) do
    {:ok, pid} = response_stream_struct.__struct__.start(response_stream_struct)
    monitor_ref = Process.monitor(pid)
    in_flight_requests = Map.put(state.in_flight_requests, ref, {pid, from, monitor_ref})
    monitor_form_refs = Map.put(state.monitor_form_refs, monitor_ref, ref)

    {:ok, %{state | in_flight_requests: in_flight_requests, monitor_form_refs: monitor_form_refs},
     pid}
  end

  def delete(state, monitor_ref) do
    {ref, monitor_form_refs} = Map.pop(state.monitor_form_refs, monitor_ref)
    {value, ifrs} = Map.pop(state.in_flight_requests, ref)
    {value, %{state | in_flight_requests: ifrs, monitor_form_refs: monitor_form_refs}}
  end

  @spec send(t, reference, any) :: :ok
  def send(state, ref, command) do
    send(elem(state.in_flight_requests[ref], 0), command)
  end

  def stop_all(state) do
    state.in_flight_requests
    |> Map.keys()
    |> Enum.each(&send(state, &1, :stop))

    new()
  end
end
