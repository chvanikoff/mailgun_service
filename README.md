# MGS

## Environments

In `dev` and `test` environments, emails are not sent to Mailgun, but processed locally. The only env to send real emails is `prod`, and `config/prod.exs` should be updated in order for the processing to work.

## Templates

Templates are located in `lib/mailgun_service_web/templates/email/` and each template is expected to have 2 versions: text with `.text.eex` extension and html with `.html.eex` extension.
Assigns can be used in the templates as they are just EEX templates.

## JSON email metadata

all the following sending methods assume the same JSON metadata format with the following keys:
  - to
  - subject
  - template
  - assigns (in case template needs it)

## Sending email via command line

Email can be sent with a mix task `mix mgs.send <json>`:

```
mix mgs.send <json>
# Example:
mix mgs.send "{\"to\":\"recepient@mailserver.tld\",\"subject\":\"testing mail service\",\"template\":\"welcome\"}"
```

## Sending email via HTTP endpoint

Authorization chosen for demonstration purpose is Basic auth, with a single username/password combination stored in config `mailgun_service.basic_auth.{username,password}`. All requests to `/api` scope are expected to have basic auth header. By default the combination is `username:password`.

Endpoint: POST `/api/v1/email` expecting json body

```bash
curl -H "Content-Type: application/json" -u username:password -d $JSON http://localhost:4000/api/v1/email
# Example:
curl -H "Content-Type: application/json" -u username:password -d "{\"to\":\"chvanikoff@gmail.com\",\"subject\":\"testing mail service\",\"template\":\"password_reset\",\"assigns\":{\"name\":\"Roman\",\"link\":\"qwe\"}}" http://localhost:4000/api/v1/email
```

## AMQP

For the demo purpose, simplest RabbitMQ setup via Docker can be used (management version is used to provide HTTP API for cli interaction in further examples):

```bash
docker run -p 15672:15672 -p 5672:5672 -d --hostname mgs-rabbit --name mgs-rabbit rabbitmq:3.7-management
```

By default, queue worker is not started, so it should be started manually.
Starting or stopping the queue worker can be achieved with iex or HTTP API.

iex:

```elixir
iex> MGS.QueueWatcher.start()
:ok
iex> MGS.QueueWatcher.stop()
:ok
```

HTTP API:

- GET `/api/v1/queue/start` to start the watcher
- GET `/api/v1/queue/stop` to stop the watcher

```bash
# start
curl -H "Content-Type: application/json" -u username:password http://localhost:4000/api/v1/queue/start
# stop
curl -H "Content-Type: application/json" -u username:password http://localhost:4000/api/v1/queue/stop
```

To enqueue an email, json with valid metadata can be enqueued in the following way:

```bash
curl -XPOST -d'{"properties":{},"routing_key":"mgs_queue","payload":$JSON,"payload_encoding":"string"}' http://guest:guest@localhost:15672/api/exchanges/%2f/mgs_exchange/publish
# Example:
curl -XPOST -d'{"properties":{},"routing_key":"mgs_queue","payload":"{\"to\":\"recepient@mailserver.tld\",\"subject\":\"testing mail service\",\"template\":\"welcome\"}","payload_encoding":"string"}' http://guest:guest@localhost:15672/api/exchanges/%2f/mgs_exchange/publish
```