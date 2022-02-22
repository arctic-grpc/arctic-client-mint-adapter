defmodule ArcticClientMintAdapter.HTTPClient do
  alias ArcticClientMintAdapter.ResponseDispatcher

  # @mint_adapter Application.get_env(:arctic_client_mint_adapter, :mint_http2_adapter)

  defmodule Address do
    defstruct [:hostname, :port, :schema]

    def new(hostname, port, schema) do
      %__MODULE__{hostname: hostname, port: port, schema: schema}
    end

    def new(hostname, port, schema) do
      %__MODULE__{hostname: hostname, port: port, schema: schema}
    end
  end

  defstruct [:address, :tls_options, :conn, :conn_error, :response_dispatcher]

  def new(hostname, port, schema, tls_options) do
    %__MODULE__{
      address: Address.new(hostname, port, schema),
      conn: nil,
      conn_error: nil,
      response_dispatcher: ResponseDispatcher.new(),
      tls_options: tls_options
    }
  end

  # TODO: handle erros like
  # connecting to HTTP1
  # Stub Mint function for testing
  def connect(client) do
    # case Mint.HTTP2.connect(client.address.schema, client.address.hostname, client.address.port) do
    case mint_adapter().connect(
           client.address.schema,
           client.address.hostname,
           client.address.port,
           client.tls_options
         ) do
      {:ok, conn} ->
        %{client | conn: conn}

      {:error, error} ->
        %{client | conn_error: to_connection_error(error)}
    end
  end

  # TODO: handle erros like
  # request failure
  # 2. take care of max open connections
  def request(client, from, path, headers, body) do
    {:ok, conn, ref} = mint_adapter().request(client.conn, "POST", path, headers, body)

    response_stream_struct =
      ArcticClientMintAdapter.ResponseStream.new(
        self(),
        from
      )

    {:ok, response_dispatcher, response_stream} =
      ResponseDispatcher.put(client.response_dispatcher, ref, from, response_stream_struct)

    {:ok, %{client | conn: conn, response_dispatcher: response_dispatcher}, response_stream}
  end

  # TODO: handle erros like
  # request failure
  # 2. take care of max open connections
  def request_stream(client, from, request) do
    {:ok, conn, ref} =
      mint_adapter().request(client.conn, "POST", request.path, request.headers, request.body)

    response_stream_struct =
      ArcticClientMintAdapter.ResponseStreamStream.new(
        self(),
        from,
        :stream,
        request.stream_reader_pid
      )

    {:ok, response_dispatcher, response_stream_pid} =
      ResponseDispatcher.put(client.response_dispatcher, ref, from, response_stream_struct)

    {:ok, %{client | conn: conn, response_dispatcher: response_dispatcher}, response_stream_pid}
  end

  def stream(client, message) do
    {conn, responses} =
      case mint_adapter().stream(client.conn, message) do
        {:ok, conn, responses} ->
          {conn, responses}

        error ->
          IO.inspect(error)
          throw(:stream_failed)
      end

    {:ok, %{client | conn: conn}, responses}
  end

  def process_responses(client, responses) do
    Enum.each(responses, fn
      {part, ref, message} ->
        ResponseDispatcher.send(client.response_dispatcher, ref, {part, message})

      {:done, ref} ->
        ResponseDispatcher.send(client.response_dispatcher, ref, :done)
    end)
  end

  def delete(client, monitor_ref) do
    {value, response_dispatcher} =
      ResponseDispatcher.delete(client.response_dispatcher, monitor_ref)

    {%{client | response_dispatcher: response_dispatcher}, elem(value, 1)}
  end

  defp to_connection_error(error) do
    error
  end

  defp mint_adapter do
    Application.get_env(
      :arctic_client_mint_adapter,
      :mint_http2_adapter,
      ArcticClientMintAdapter.MintHTTP2
    )
  end
end
