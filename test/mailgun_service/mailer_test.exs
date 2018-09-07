defmodule MGS.MailerTest do
  use ExUnit.Case, async: false
  use Bamboo.Test, shared: true

  alias MGS.Mailer

  @attrs %{
    to: "test@mail.com",
    subject: "test subject",
    body: "hello"
  }

  describe "email_from_json/1" do
    test "Valid json" do
      to = @attrs.to
      subject = @attrs.subject
      body = @attrs.body
      json = Poison.encode!(%{to: to, subject: subject, body: body})

      assert match?(
               {:ok,
                %Bamboo.Email{to: ^to, subject: ^subject, html_body: ^body, text_body: ^body}},
               Mailer.email_from_json(json)
             )
    end

    test "Correct error for invalid json" do
      <<_, invalid_json::binary>> =
        Poison.encode!(%{to: @attrs.to, subject: @attrs.subject, body: @attrs.body})

      expected = {:error, "Invalid JSON"}
      assert Mailer.email_from_json(invalid_json) == expected
    end

    test "Correct error for non-json string" do
      not_a_json = "not a json"

      expected = {:error, "Invalid JSON"}
      assert Mailer.email_from_json(not_a_json) == expected
    end

    test "Correct error for insufficient keys" do
      json = Poison.encode!(%{recepient: @attrs.to, subject: @attrs.subject, body: @attrs.body})

      expected =
        {:error,
         "Invalid keys, expected \"to\", \"subject\" and \"body\"" <>
           ", got: %{\"body\" => \"#{@attrs.body}\", \"recepient\" => \"#{@attrs.to}\"," <>
           " \"subject\" => \"#{@attrs.subject}\"}"}

      assert Mailer.email_from_json(json) == expected
    end
  end
end
