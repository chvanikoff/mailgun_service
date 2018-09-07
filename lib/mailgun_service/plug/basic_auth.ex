defmodule Plug.BasicAuth do
  @moduledoc """
  Generic Basic auth plug
  """

  import Plug.{Conn, Crypto}

  def init(otp_app: otp_app) do
    otp_app
    |> Application.get_env(:basic_auth)
    |> Enum.into(%{})
    |> Map.put_new(:realm, "Basic Authentication")
    |> init()
  end

  def init(%{username: _username, password: _password, realm: _realm} = opts) do
    opts
  end

  def call(conn, opts) do
    with ["Basic " <> encoded] <- get_req_header(conn, "authorization"),
         {:ok, token} <- Base.decode64(encoded),
         true <- secure_compare(token, "#{opts[:username]}:#{opts[:password]}") do
      conn
    else
      _error ->
        conn
        |> put_resp_header("www-authenticate", "Basic realm=\"#{opts[:realm]}\"")
        |> put_resp_content_type("text/plain")
        |> send_resp(401, "401 Unauthorized")
        |> halt()
    end
  end
end
