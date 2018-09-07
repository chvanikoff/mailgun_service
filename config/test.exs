use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mailgun_service, MGSWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :mailgun_service, MGS.Mailer, adapter: Bamboo.TestAdapter

config :bamboo, :refute_timeout, 100

config :mailgun_service, :hammer,
  window: 500,
  size: 3