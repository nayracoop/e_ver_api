defmodule EVerApiWeb.SponsorControllerTest do
  use EVerApiWeb.ConnCase

  alias EVerApi.Sponsors
  alias EVerApi.Sponsors.Sponsor

  @create_attrs %{
    logo: "some logo",
    name: "some name",
    website: "some website"
  }
  @update_attrs %{
    logo: "some updated logo",
    name: "some updated name",
    website: "some updated website"
  }
  @invalid_attrs %{logo: nil, name: nil, website: nil}

  def fixture(:sponsor) do
    {:ok, sponsor} = Sponsors.create_sponsor(@create_attrs)
    sponsor
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  # describe "index" do
  #   test "lists all sponsors", %{conn: conn} do
  #     conn = get(conn, Routes.sponsor_path(conn, :index))
  #     assert json_response(conn, 200)["data"] == []
  #   end
  # end

  describe "with a logged-in user" do
    setup %{conn: conn, login_as: email} do
      user = insert(:user, email: email)
      event = insert(:event, %{user: user})
      {:ok, jwt_string, _} = EVerApi.Accounts.token_sign_in(email, "123456")

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Bearer #{jwt_string}")

      {:ok, conn: conn, user: user, event: event}
    end

    # CREATE SPONSOR
    @tag individual_test: "sponsors_create", login_as: "email@email.com"
    test "renders sponsor when data is valid", %{conn: conn, user: user, event: event} do
      conn = post(conn, Routes.sponsor_path(conn, :create, event.id), sponsor: @create_attrs)

      assert %{
               "id" => sponsor_id,
               "logo" => "some logo",
               "name" => "some name",
               "website" => "some website"
             } = json_response(conn, 201)["data"]

      # fetch the event and check
      conn = get(conn, Routes.event_path(conn, :show, event.id))
      assert response = json_response(conn, 200)["data"]

      sponsors = response["sponsors"]

      assert Enum.count(sponsors) == 3
      sp = Enum.find(sponsors, fn x -> x["id"] == sponsor_id end)
      assert %{
        "id" => sponsor_id,
        "logo" => "some logo",
        "name" => "some name",
        "website" => "some website"
      } = sp
    end

    @tag individual_test: "sponsors_create", login_as: "email@email.com"
    test "renders errors when data is invalid", %{conn: conn, user: user, event: event} do
      conn = post(conn, Routes.sponsor_path(conn, :create, event.id), sponsor: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update sponsor" do
    setup [:create_sponsor]

    test "renders sponsor when data is valid", %{conn: conn, sponsor: %Sponsor{id: id} = sponsor} do
      conn = put(conn, Routes.sponsor_path(conn, :update, sponsor), sponsor: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.sponsor_path(conn, :show, id))

      assert %{
               "id" => id,
               "logo" => "some updated logo",
               "name" => "some updated name",
               "website" => "some updated website"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, sponsor: sponsor} do
      conn = put(conn, Routes.sponsor_path(conn, :update, sponsor), sponsor: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete sponsor" do
    setup [:create_sponsor]

    test "deletes chosen sponsor", %{conn: conn, sponsor: sponsor} do
      conn = delete(conn, Routes.sponsor_path(conn, :delete, sponsor))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.sponsor_path(conn, :show, sponsor))
      end
    end
  end

  defp create_sponsor(_) do
    sponsor = fixture(:sponsor)
    %{sponsor: sponsor}
  end
end
