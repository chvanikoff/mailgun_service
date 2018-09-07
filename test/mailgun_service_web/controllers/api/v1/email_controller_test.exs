defmodule MGSWeb.API.V1.EmailControllerTest do
  use MGSWeb.ConnCase

  @attrs %{
    to: "test@mail.com",
    subject: "test subject",
    template: "welcome"
  }

  describe "Authorization" do
    test "Unauthorized conn receives 401 error response", %{conn: conn} do
      params = %{to: @attrs.to, subject: @attrs.subject, template: @attrs.template}

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(api_v1_email_path(conn, :send), params)

      assert text_response(conn, 401)
    end
  end

  describe "POST /api/v1/email" do
    test "Sends email when params are valid", %{authorized_conn: conn} do
      params = %{to: @attrs.to, subject: @attrs.subject, template: @attrs.template}

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(api_v1_email_path(conn, :send), params)

      response = json_response(conn, 200)
      assert response["status"] == "ok"
      assert response["error"] == nil
    end

    test "Returns error when params are invalid", %{authorized_conn: conn} do
      invalid_params = %{recipient: @attrs.to, subject: @attrs.subject, template: @attrs.template}

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(api_v1_email_path(conn, :send), invalid_params)

      response = json_response(conn, 200)
      assert response["status"] == "error"

      assert response["error"] ==
               "Invalid keys, expected \"to\", " <>
                 "\"subject\" and \"template\", got: %{\"recipient\" => \"test@mail.com\", " <>
                 "\"subject\" => \"test subject\", \"template\" => \"welcome\"}"
    end
  end
end
