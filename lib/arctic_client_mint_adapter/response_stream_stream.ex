defmodule ArcticClientMintAdapter.ResponseStreamStream do
  @moduledoc """
  A GenServer to collect data coming from Mint HTTP frame. It collects
  the data into %ArcticClient.UnaryResponse{} and sends back the struct
  when `:done` is received to the `request_caller`
  """
  use GenServer
  alias Arctic.StreamResponse

  defstruct [:response, :connection_pid, :request_caller, :type, :stream_reader_pid]

  @type t :: %__MODULE__{
          connection_pid: pid,
          request_caller: GenServer.from(),
          response: map
        }

  @spec start(t()) :: GenServer.on_start()
  def start(%__MODULE__{} = struct) do
    GenServer.start(__MODULE__, struct, [])
  end

  def new(connection_pid, request_caller, type \\ :unray, stream_reader_pid \\ nil) do
    %__MODULE__{
      connection_pid: connection_pid,
      request_caller: request_caller,
      stream_reader_pid: stream_reader_pid,
      type: type,
      response: %StreamResponse{headers: []}
    }
  end

  @impl GenServer
  def init(struct) do
    # TODO: Monitor the pid and exit when it's failed
    {:ok, struct}
  end

  @impl GenServer
  def handle_info({:status, status}, state) do
    response = %{state.response | status: status}
    {:noreply, %{state | response: response}}
  end

  @impl GenServer
  def handle_info({:headers, headers}, state) do
    headers = state.response.headers ++ headers

    response =
      %{state.response | headers: headers}
      |> IO.inspect()

    {:noreply, %{state | response: response}}
  end

  @impl GenServer
  def handle_info({:data, data}, state) do
    IO.inspect(data)
    send(state.stream_reader_pid, {:data, state.response, data})
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:done, state) do
    response = %{state.response | done: true}
    send(state.stream_reader_pid, {:done, response})
    state = %{state | response: response}
    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_info(:stop, state) do
    {:stop, :normal, state}
  end
end
