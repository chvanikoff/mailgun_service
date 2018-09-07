defmodule MGS.MailerTest do
  use ExUnit.Case, async: false
  use Bamboo.Test, shared: true

  alias MGS.Mailer

  @attrs %{
    to: "test@mail.com",
    subject: "test subject",
    template: "welcome"
  }

  describe "email_from_json/1" do
    test "Valid json" do
      to = @attrs.to
      subject = @attrs.subject
      template = @attrs.template
      json = Poison.encode!(%{to: to, subject: subject, template: template})

      assert match?(
               {:ok, %Bamboo.Email{to: ^to, subject: ^subject}},
               Mailer.email_from_json(json)
             )
    end

    test "Template is set" do
      json = Poison.encode!(%{to: @attrs.to, subject: @attrs.subject, template: @attrs.template})

      {:ok, %Bamboo.Email{html_body: html_body, text_body: text_body}} =
        Mailer.email_from_json(json)

      assert html_body =~ "<body>"
      assert html_body =~ "Welcome"
      assert html_body =~ "</body>"

      assert text_body =~ "Welcome"
    end

    test "Template with assigns" do
      template = "password_reset"
      name = "Roman"
      link = "https://google.com"

      json =
        Poison.encode!(%{
          to: @attrs.to,
          subject: @attrs.subject,
          template: template,
          assigns: %{name: name, link: link}
        })

      {:ok, %Bamboo.Email{html_body: html_body, text_body: text_body}} =
        Mailer.email_from_json(json)

      assert html_body =~ "<body>"
      assert html_body =~ name
      assert html_body =~ "visit the link"
      assert html_body =~ link
      assert html_body =~ "</body>"

      assert text_body =~ name
      assert text_body =~ "visit the link"
      assert text_body =~ link
    end

    test "Correct error when no required assigns passed" do
      template = "password_reset"
      json = Poison.encode!(%{to: @attrs.to, subject: @attrs.subject, template: template})

      expected = {:error, "Valid assigns must be provided for template #{template}"}
      assert Mailer.email_from_json(json) == expected
    end

    test "Correct error for non-existing template" do
      _existing_atom = :invalid
      tpl = "invalid"
      json = Poison.encode!(%{to: @attrs.to, subject: @attrs.subject, template: tpl})

      expected = {:error, "Template \"#{tpl}\" not found"}
      assert Mailer.email_from_json(json) == expected
    end

    test "Correct error for non-existing template when template name doesn't exist as an atom" do
      tpl = "there should be no such weird atom in app memory"
      json = Poison.encode!(%{to: @attrs.to, subject: @attrs.subject, template: tpl})

      expected = {:error, "Template \"#{tpl}\" not found"}
      assert Mailer.email_from_json(json) == expected
    end

    test "Correct error for invalid json" do
      <<_, invalid_json::binary>> =
        Poison.encode!(%{to: @attrs.to, subject: @attrs.subject, template: @attrs.template})

      expected = {:error, "Invalid JSON"}
      assert Mailer.email_from_json(invalid_json) == expected
    end

    test "Correct error for non-json string" do
      not_a_json = "not a json"

      expected = {:error, "Invalid JSON"}
      assert Mailer.email_from_json(not_a_json) == expected
    end

    test "Correct error for insufficient keys" do
      json =
        Poison.encode!(%{recepient: @attrs.to, subject: @attrs.subject, template: @attrs.template})

      expected =
        {:error,
         "Invalid keys, expected \"to\", \"subject\" and \"template\"" <>
           ", got: %{\"recepient\" => \"#{@attrs.to}\"," <>
           " \"subject\" => \"#{@attrs.subject}\", \"template\" => \"#{@attrs.template}\"}"}

      assert Mailer.email_from_json(json) == expected
    end
  end

  describe "Rate-limit" do
    setup do
      on_exit(fn -> {:ok, _} = Hammer.delete_buckets("mgs:send_email") end)
      :ok
    end

    test "Returns error when limit exceeded" do
      json = Poison.encode!(%{to: @attrs.to, subject: @attrs.subject, template: @attrs.template})

      {:ok, email} = Mailer.email_from_json(json)
      assert match?(%Bamboo.Email{}, Mailer.send(email))
      assert match?(%Bamboo.Email{}, Mailer.send(email))
      assert match?(%Bamboo.Email{}, Mailer.send(email))
      assert Mailer.send(email) == {:error, "Rate limit exceeded, try again later"}
    end

    test "Recovers" do
      json = Poison.encode!(%{to: @attrs.to, subject: @attrs.subject, template: @attrs.template})

      {:ok, email} = Mailer.email_from_json(json)
      assert match?(%Bamboo.Email{}, Mailer.send(email))
      assert match?(%Bamboo.Email{}, Mailer.send(email))
      assert match?(%Bamboo.Email{}, Mailer.send(email))
      assert Mailer.send(email) == {:error, "Rate limit exceeded, try again later"}
      Process.sleep(500)
      assert match?(%Bamboo.Email{}, Mailer.send(email))
    end
  end
end
