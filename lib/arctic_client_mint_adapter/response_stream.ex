defmodule ArcticClientMintAdapter.ResponseStream do
  @moduledoc """
  A GenServer to collect data coming from Mint HTTP frame. It collects
  the data into %ArcticClient.UnaryResponse{} and sends back the struct
  when `:done` is received to the `request_caller`
  """
  use GenServer
  alias ArcticClient.UnaryResponse

  defstruct [:response, :connection_pid, :request_caller]

  @type t :: %__MODULE__{
          connection_pid: pid,
          request_caller: GenServer.from(),
          response: map
        }

  @spec start(pid, GenServer.from()) :: GenServer.on_start()
  def start(connection_pid, request_caller) do
    GenServer.start(__MODULE__, [connection_pid, request_caller], [])
  end

  defp new([connection_pid, request_caller]) do
    %__MODULE__{
      connection_pid: connection_pid,
      request_caller: request_caller,
      response: %UnaryResponse{data: <<>>, headers: [], data: []}
    }
  end

  @impl GenServer
  def init(opts) do
    # TODO: Monitor the pid and exit when it's failed
    {:ok, new(opts)}
  end

  @impl GenServer
  def handle_info({:status, status}, state) do
    response = %{state.response | status: status}
    {:noreply, %{state | response: response}}
  end

  @impl GenServer
  def handle_info({:headers, headers}, state) do
    headers = state.response.headers ++ headers
    response = %{state.response | headers: headers}
    {:noreply, %{state | response: response}}
  end

  @impl GenServer
  def handle_info({:data, data}, state) do
    data = [data | state.response.data]

    response = %{state.response | data: data}
    {:noreply, %{state | response: response}}
  end

  @impl GenServer
  def handle_info(:done, state) do
    data = state.response.data |> Enum.reverse() |> IO.iodata_to_binary()
    response = %{state.response | done: true, data: data}
    state = %{state | response: response}
    GenServer.reply(state.request_caller, response)
    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_info(:stop, state) do
    {:stop, :normal, state}
  end
end
