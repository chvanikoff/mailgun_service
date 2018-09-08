defmodule MGSWeb.API.V1.QueueController do
  use MGSWeb, :controller

  alias MGS.Mailer

  def set_status(conn, %{"status" => status}) when status in ["start", "stop"] do
    response =
      case apply(MGS.QueueWatcher, String.to_atom(status), []) do
        :ok ->
          %{"status" => "ok", "error" => nil}

        {:error, error} ->
          %{"status" => "error", "error" => error}
      end
    json(conn, response)
  end
end
