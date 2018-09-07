defmodule Mix.Tasks.Mgs.Send do
  @moduledoc """
  A task to send email via Mailgun.
  Expects a json string to be passed with following keys:
  "to": recepient email
  "subject": message subject
  "template": message template
  "assigns": assigns for template (can be omited if not required by template)

  Usage:
      
      mix mgs.send <json>

  Example:

      mix mgs.send "{\"to\":\"recepient@mailserver.tld\",\"subject\":\"testing mail service\",\"template\":\"welcome\"}"

  """

  use Mix.Task

  alias MGS.Mailer

  @doc false
  def run([json]) do
    Mix.Task.run("app.start", [])

    with {:ok, email} <- Mailer.email_from_json(json),
         %Bamboo.Email{} <- Mailer.send(email) do
      IO.puts("Email have been sent to #{email.to}")
    else
      {:error, error} ->
        IO.puts("Error: #{error}")
    end
  end
end
