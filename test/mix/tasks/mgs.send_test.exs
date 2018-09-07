defmodule Mix.Tasks.Mgs.SendTest do
  use ExUnit.Case, async: false
  use Bamboo.Test, shared: true

  import ExUnit.CaptureIO

  @attrs %{
    to: "test@mail.com",
    subject: "test subject",
    template: "welcome"
  }

  describe "mix mgs.send" do
    test "Sends an email when json is valid" do
      json = Poison.encode!(%{to: @attrs.to, subject: @attrs.subject, template: @attrs.template})

      assert capture_io(fn -> Mix.Tasks.Mgs.Send.run([json]) end) ==
               "Email have been sent to #{@attrs.to}\n"

      expected = [
        to: [nil: @attrs.to],
        subject: @attrs.subject,
        html_body: ~r/<body>.*?welcome.*?<\/body>/si,
        text_body: ~r/welcome/i
      ]

      assert_email_delivered_with(expected)
    end

    test "Shows an error if any" do
      <<_, invalid_json::binary>> =
        Poison.encode!(%{to: @attrs.to, subject: @attrs.subject, template: @attrs.template})

      assert capture_io(fn -> Mix.Tasks.Mgs.Send.run([invalid_json]) end) ==
               "Error: Invalid JSON\n"

      assert_no_emails_delivered()
    end
  end
end
