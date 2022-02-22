defmodule ArcticClientMintAdapter.HTTPClientServer do
  @moduledoc """
  This GenServer is managing single HTTP connection.

  When this gen_server receives :request call, it spawns a new
  process and let the caller to await on this new process for data.
  This allows HTTPClient to still be responsive to other part of the system
  and also recieve http packages.
  """
  use GenServer
  alias ArcticClientMintAdapter.HTTPClient

  @doc """
  Returns the status of the http connection
  """
  @spec check_connection_status(pid) :: :ok | {:error, any}
  def check_connection_status(pid) do
    GenServer.call(pid, :check_connection_status)
  end

  @doc """
  Make a unary request
  """
  @spec request(pid, String.t(), String.t(), keyword) :: {:ok, pid}
  def request_stream(pid, request, timeout \\ 5000) do
    GenServer.call(pid, {:request, :stream, request}, timeout)
  end

  @doc """
  Make a unary request
  """
  @spec request(pid, String.t(), String.t(), keyword) :: {:ok, pid}
  def request(pid, path, body, headers, timeout \\ 5000) do
    try do
      GenServer.call(pid, {:request, :unary, path, body, headers}, timeout)
    catch
      :exit, _ ->
        check_connection_status(pid)
    end
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  @impl GenServer
  def init(opts) do
    state = HTTPClient.new(opts[:hostname], opts[:port], opts[:schema], opts[:tls_options])

    {:ok, state, {:continue, :connect}}
  end

  @impl GenServer
  def handle_continue(:connect, state) do
    state = HTTPClient.connect(state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:check_connection_status, _from, state) do
    case state.conn_error do
      nil -> {:reply, :ok, state}
      error -> {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:request, :unary, _, _, _}, _from, %{conn: nil} = state) do
    # TODO: queue the call to be exeucted again
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:request, :stream, request}, from, state) do
    {:ok, state, _} = HTTPClient.request_stream(state, from, request)

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:request, :unary, path, body, headers}, from, state) do
    {:ok, state, _} = HTTPClient.request(state, from, path, headers, body)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({socket_type, _, _} = message, state) when socket_type in [:tcp, :ssl] do
    case HTTPClient.stream(state, message) do
      {:ok, state, responses} ->
        HTTPClient.process_responses(state, responses)
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info({closed, _}, state) when closed in [:tcp_closed, :ssl_closed] do
    # response_dispatcher = ResponseDispatcher.stop_all(state.response_dispatcher)

    state = schedule_reconnect(state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:reconnection, state) do
    state = HTTPClient.connect(state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _pid, :normal}, state) do
    {state, _caller} = HTTPClient.delete(state, ref)
    {:noreply, state}
  end

  defp schedule_reconnect(state) do
    Process.send_after(self(), :reconnection, 1000)
    state
  end
end
