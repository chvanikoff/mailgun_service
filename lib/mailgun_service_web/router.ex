defmodule MGSWeb.Router do
  use MGSWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(Plug.BasicAuth, otp_app: :mailgun_service)
  end

  scope "/api", MGSWeb.API, as: :api do
    pipe_through(:api)

    scope "/v1", V1, as: :v1 do
      post("/email", EmailController, :send)
    end
  end
end
