defmodule MGSWeb.API.V1.QueueControllerTest do
  use MGSWeb.ConnCase, async: false

  describe "GET /api/v1/queue/:status" do
    setup do
      on_exit(fn ->
        case MGS.QueueWatcher.stop() do
          :ok -> :ok
          {:error, :already_stopped} -> :ok
        end
      end)
      :ok
    end

    test "Starts queue when it is stopped", %{authorized_conn: conn} do
      conn
      |> put_req_header("content-type", "application/json")
      |> get(api_v1_queue_path(conn, :set_status, "stop"))

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> get(api_v1_queue_path(conn, :set_status, "start"))

      response = json_response(conn, 200)
      assert response["status"] == "ok"
      assert response["error"] == nil
    end

    test "Return already_started error", %{authorized_conn: conn} do
      conn
      |> put_req_header("content-type", "application/json")
      |> get(api_v1_queue_path(conn, :set_status, "start"))

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> get(api_v1_queue_path(conn, :set_status, "start"))

      response = json_response(conn, 200)
      assert response["status"] == "error"
      assert response["error"] == "already_started"
    end

    test "Stops queue when it is started", %{authorized_conn: conn} do
      conn
      |> put_req_header("content-type", "application/json")
      |> get(api_v1_queue_path(conn, :set_status, "start"))

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> get(api_v1_queue_path(conn, :set_status, "stop"))

      response = json_response(conn, 200)
      assert response["status"] == "ok"
      assert response["error"] == nil
    end

    test "Return already_stopped error", %{authorized_conn: conn} do
      conn
      |> put_req_header("content-type", "application/json")
      |> get(api_v1_queue_path(conn, :set_status, "stop"))

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> get(api_v1_queue_path(conn, :set_status, "stop"))

      response = json_response(conn, 200)
      assert response["status"] == "error"
      assert response["error"] == "already_stopped"
    end
  end
end
