defmodule MGS.QueueWatcherTest do
  use ExUnit.Case, async: false
  use Bamboo.Test, shared: true

  @attrs %{
    to: "test@mail.com",
    subject: "test subject",
    template: "welcome"
  }

  setup_all do
    :ok = MGS.QueueWatcher.start()
    config = Application.get_env(:mailgun_service, :amqp) |> Enum.into(%{})
    {:ok, conn} = AMQP.Connection.open(config[:connection_string])
    {:ok, chan} = AMQP.Channel.open(conn)

    on_exit(fn -> :ok = MGS.QueueWatcher.stop() end)

    {:ok,
     %{
       chan: chan,
       exchange: config[:exchange],
       status_queue: config[:status_queue],
       queue: config[:queue]
     }}
  end

  describe "Queued emails" do
    test "Sent when data is valid", %{
      chan: chan,
      exchange: exchange,
      queue: queue,
      status_queue: status_queue
    } do
      json =
        Poison.encode!(%{
          to: @attrs.to,
          subject: @attrs.subject,
          template: @attrs.template
        })

      :ok = AMQP.Basic.publish(chan, exchange, queue, json)

      expected = [
        to: [nil: @attrs.to],
        subject: @attrs.subject,
        html_body: ~r/<body>.*?welcome.*?<\/body>/si,
        text_body: ~r/welcome/i
      ]

      assert_email_delivered_with(expected)

      {:ok, _} = AMQP.Queue.purge(chan, status_queue)
    end

    test "Not sent when data is invalid", %{
      chan: chan,
      exchange: exchange,
      queue: queue,
      status_queue: status_queue
    } do
      json =
        Poison.encode!(%{
          recipient: @attrs.to,
          subject: @attrs.subject,
          template: @attrs.template
        })

      :ok = AMQP.Basic.publish(chan, exchange, queue, json)
      assert_no_emails_delivered()
      {:ok, _} = AMQP.Queue.purge(chan, status_queue)
    end
  end

  describe "Status queue" do
    test "Success status is queued", %{
      chan: chan,
      status_queue: status_queue,
      queue: queue,
      exchange: exchange
    } do
      {:ok, _} = AMQP.Queue.purge(chan, status_queue)
      {:ok, tag} = AMQP.Basic.consume(chan, status_queue, self())

      json =
        Poison.encode!(%{
          to: @attrs.to,
          subject: @attrs.subject,
          template: @attrs.template
        })

      :ok = AMQP.Basic.publish(chan, exchange, queue, json)
      assert_receive {:basic_deliver, status_msg, _}, 1000
      msg = Poison.decode!(status_msg)
      assert msg["status"] == "ok"
      assert msg["error"] == nil
      {:ok, _} = AMQP.Basic.cancel(chan, tag)
      assert_email_delivered_with(%{to: [nil: @attrs.to]})
      {:ok, _} = AMQP.Queue.purge(chan, status_queue)
    end

    test "Error status is queued", %{
      chan: chan,
      status_queue: status_queue,
      queue: queue,
      exchange: exchange
    } do
      {:ok, _} = AMQP.Queue.purge(chan, status_queue)
      {:ok, tag} = AMQP.Basic.consume(chan, status_queue, self())

      json =
        Poison.encode!(%{
          recipient: @attrs.to,
          subject: @attrs.subject,
          template: @attrs.template
        })

      :ok = AMQP.Basic.publish(chan, exchange, queue, json)
      assert_receive {:basic_deliver, status_msg, _}, 1000
      msg = Poison.decode!(status_msg)
      assert msg["status"] == "error"
      assert msg["error"] =~ "Invalid keys"
      {:ok, _} = AMQP.Basic.cancel(chan, tag)
    end
  end
end
