defmodule MGS.Mailer do
  @moduledoc """
  Module for sending emails
  """

  use Bamboo.Mailer, otp_app: :mailgun_service

  use Bamboo.Phoenix, view: MGSWeb.EmailView

  @doc """
  Convert json with email params into Bamboo email struct.
  "body" parameter is added to both text and html versions of email.

  ## Example

      iex> email_from_json("{\"to\":\"recepient@mailserver.tld\",\"subject\":\"testing mail service\",\"body\":\"Hello\"}")
      {:ok, %Bamboo.Email{to: [nil: "recepient@mailserver.tld"], subject: "testing mail service", text_body: "Hello", html_body: "Hello"}}

      iex> email_from_json("not a json")
      {:error, "Unexpected token at position 0: n"}

  """
  @spec email_from_json(String.t()) :: {:ok, Bamboo.Email.t()} | {:error, String.t()}
  def email_from_json(json) do
    with {:ok, data} <- Poison.decode(json),
         %{"to" => to, "subject" => subject, "body" => body} <- data do
      email =
        new_email()
        |> from(Application.get_env(:mailgun_service, MGS.Mailer)[:from])
        |> to(to)
        |> html_body(body)
        |> text_body(body)
        |> subject(subject)

      {:ok, email}
    else
      %{} = invalid ->
        {:error,
         "Invalid keys, expected \"to\", \"subject\" and \"body\", got: #{inspect(invalid)}"}

      {:error, {:invalid, token, pos}} when is_binary(token) and is_integer(pos) ->
        {:error, "Invalid JSON"}

      {:error, :invalid, pos} when is_integer(pos) ->
        {:error, "Invalid JSON"}
    end
  end
end
