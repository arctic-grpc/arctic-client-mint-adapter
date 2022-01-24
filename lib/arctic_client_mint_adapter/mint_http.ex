defmodule ArcticClientMintAdapter.MintHTTP2 do
  @callback connect(Mint.Types.scheme(), Mint.Types.address(), :inet.port_number()) ::
              {:ok, Mint.HTTP2.t()} | {:error, Mint.Types.error()}

  @callback request(
              Mint.HTTP2.t(),
              method :: String.t(),
              path :: String.t(),
              Types.headers(),
              body :: iodata() | nil | :stream
            ) ::
              {:ok, Mint.HTTP2.t(), Mint.Types.request_ref()}
              | {:error, Mint.HTTP2.t(), Mint.Types.error()}

  @callback stream(Mint.HTTP2.t(), term()) ::
              {:ok, Mint.HTTP2.t(), [Mint.Types.response()]}
              | {:error, Mint.HTTP2.t(), Mint.Types.error(), [Mint.Types.response()]}
              | :unknown

  @behaviour __MODULE__

  @impl __MODULE__
  def connect(schema, address, port) do
    Mint.HTTP2.connect(schema, address, port)
  end

  @impl __MODULE__
  def request(conn, method, path, headers, body) do
    Mint.HTTP2.request(conn, method, path, headers, body)
  end

  @impl __MODULE__
  def stream(conn, message) do
    Mint.HTTP2.stream(conn, message)
  end
end
