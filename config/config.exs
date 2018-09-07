# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :mailgun_service,
  namespace: MGS

# Configures the endpoint
config :mailgun_service, MGSWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "mMsMB9Et+GEK2Pxh6kYcwrgTWMv+WvXkbu+mHjp0rt0xc2Z6ACtKjtvR9lHRvBe4",
  render_errors: [view: MGSWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: MGS.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"