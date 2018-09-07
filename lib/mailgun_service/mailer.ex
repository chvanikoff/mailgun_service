defmodule MGS.Mailer do
  @moduledoc """
  Module for sending emails
  """

  use Bamboo.Mailer, otp_app: :mailgun_service

  use Bamboo.Phoenix, view: MGSWeb.EmailView

  @doc """
  Convert json with email params into Bamboo email struct

  ## Example

      iex> email_from_json("{\"to\":\"recepient@mailserver.tld\",\"subject\":\"testing mail service\",\"template\":\"welcome\"}")
      {:ok, %Bamboo.Email{to: [nil: "recepient@mailserver.tld"], subject: "testing mail service", text_body: "welcome", html_body: "<html>...</html>"}}

      iex> email_from_json("not a json")
      {:error, "Unexpected token at position 0: n"}

  """
  @spec email_from_json(String.t()) :: {:ok, Bamboo.Email.t()} | {:error, String.t()}
  def email_from_json(json) do
    with {:ok, data} <- Poison.decode(json),
         %{"to" => to, "subject" => subject, "template" => template} <- data do
      email =
        new_email()
        |> from(Application.get_env(:mailgun_service, MGS.Mailer)[:from])
        |> to(to)
        |> subject(subject)

      try do
        assigns =
          data
          |> Map.get("assigns", [])
          |> Enum.into([], fn {k, v} -> {String.to_existing_atom(k), v} end)

        template =
          template
          |> String.downcase()
          |> String.to_existing_atom()

        {:ok, render(email, template, assigns)}
      catch
        # atom with template name doesn't exist
        :error, :badarg ->
          {:error, "Template \"#{template}\" not found"}

        # template doesn't exist
        :error, %Phoenix.Template.UndefinedError{} ->
          {:error, "Template \"#{template}\" not found"}

        # Required assigns for the template are not available, EEX engine will produce a warning
        # via IO.warn/1, which can't be disabled or omitted by changing Logger level
        :error, %ArgumentError{} ->
          {:error, "Valid assigns must be provided for template #{template}"}
      end
    else
      %{} = invalid ->
        {:error,
         "Invalid keys, expected \"to\", \"subject\" and \"template\", got: #{inspect(invalid)}"}

      {:error, {:invalid, token, pos}} when is_binary(token) and is_integer(pos) ->
        {:error, "Invalid JSON"}

      {:error, :invalid, pos} when is_integer(pos) ->
        {:error, "Invalid JSON"}
    end
  end

  @doc """
  Returns list of available templates.
  Also allows us to use String.to_existing_atom/1 when accepting template param
  and converting it to atom.
  """
  @spec templates() :: [atom()]
  def templates() do
    [:welcome, :password_reset]
  end
end
