defmodule MGS.QueueWatcher do
  @moduledoc """
  GenServer worker watching AMQP (RabbitMQ) queue and 
  sending emails from queued metadata in background
  """

  use GenServer
  use AMQP

  require Logger

  alias MGS.Mailer

  @reconnect_timeout 5_000

  @doc """
  Starts actual queue processing: subscribe to relevant queue and send enqueued emails
  """
  @spec start() :: :ok | {:error, :already_started}
  def start() do
    GenServer.call(__MODULE__, :start)
  end

  @doc """
  Stops the queue processing disconnecting from RabbitMQ
  """
  @spec stop() :: :ok | {:error, :already_stopped}
  def stop() do
    GenServer.call(__MODULE__, :stop)
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    {:ok, %{chan: nil, config: get_config()}}
  end

  def handle_call(:start, _from, %{chan: nil} = state) do
    {:ok, chan} = connect(state.config)
    {:reply, :ok, %{state | chan: chan}}
  end

  def handle_call(:start, _from, state) do
    {:reply, {:error, :already_started}, state}
  end

  def handle_call(:stop, _from, %{chan: nil} = state) do
    {:reply, {:error, :already_stopped}, state}
  end

  def handle_call(:stop, _from, %{chan: chan} = state) do
    :ok = AMQP.Connection.close(chan.conn)
    {:reply, :ok, %{state | chan: nil}}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, state) do
    {:noreply, state}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, state) do
    {:noreply, state}
  end

  def handle_info({:basic_deliver, json, %{delivery_tag: tag}}, %{chan: chan} = state) do
    status =
      with {:ok, email} <- Mailer.email_from_json(json),
           %Bamboo.Email{} <- Mailer.send(email) do
        :ok = Basic.ack(chan, tag)
        %{"status" => "ok", "error" => nil}
      else
        {:error, error} ->
          :ok = Basic.reject(chan, tag, requeue: false)
          %{"status" => "error", "error" => error}
      end

    response =
      status
      |> Map.put("tag", tag)
      |> Poison.encode!()

    :ok = Basic.publish(chan, state.config.exchange, state.config.status_queue, response)
    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, state) do
    {:ok, chan} = connect(state.config)
    {:noreply, %{state | chan: chan}}
  end

  defp get_config() do
    :mailgun_service
    |> Application.get_env(:amqp)
    |> Enum.into(%{})
  end

  defp connect(
         %{
           connection_string: connection_string,
           queue: queue,
           status_queue: status_queue,
           exchange: exchange
         } = config
       ) do
    with {:ok, conn} <- Connection.open(connection_string),
         {:ok, chan} <- Channel.open(conn),
         :ok <- setup_queues(queue, status_queue, exchange, chan),
         {:ok, _consumer_tag} <- Basic.consume(chan, queue) do
      {:ok, chan}
    else
      error ->
        Logger.error("Error connecting to RabbitMQ: #{inspect(error)}")
        Process.sleep(@reconnect_timeout)
        connect(config)
    end
  end

  defp setup_queues(queue, status_queue, exchange, chan) do
    {:ok, _} = Queue.declare(chan, queue, durable: false)
    {:ok, _} = Queue.declare(chan, status_queue, durable: false)
    :ok = Exchange.topic(chan, exchange, durable: false)
    :ok = Queue.bind(chan, queue, exchange, routing_key: queue)
    :ok = Queue.bind(chan, status_queue, exchange, routing_key: status_queue)
  end
end
