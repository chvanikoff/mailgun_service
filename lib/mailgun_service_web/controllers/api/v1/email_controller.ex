defmodule MGSWeb.API.V1.EmailController do
  use MGSWeb, :controller

  alias MGS.Mailer

  def send(conn, params) do
    response =
      with {:ok, email} <- Mailer.email_from_map(params),
           %Bamboo.Email{} <- Mailer.send(email) do
        %{"status" => "ok", "error" => nil}
      else
        {:error, error} ->
          %{"status" => "error", "error" => error}
      end

    json(conn, response)
  end
end
