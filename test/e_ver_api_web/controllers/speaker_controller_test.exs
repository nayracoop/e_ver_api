defmodule EVerApiWeb.SpeakerControllerTest do
  use EVerApiWeb.ConnCase, async: true
  @moduletag :speakers_controller_case

  alias EVerApi.Ever
  alias EVerApi.Ever.Speaker

  @create_attrs %{
    avatar: "some avatar",
    bio: "some bio",
    company: "some company",
    first_name: "some first_name",
    last_name: "some last_name",
    name: "some name",
    role: "some role"
  }
  @update_attrs %{
    avatar: "some updated avatar",
    bio: "some updated bio",
    company: "some updated company",
    first_name: "some updated first_name",
    last_name: "some updated last_name",
    name: "some updated name",
    role: "some updated role"
  }
  @invalid_attrs %{
    avatar: nil,
    bio: nil,
    company: nil,
    first_name: nil,
    last_name: nil,
    name: nil,
    role: nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "with a logged-in user" do
    setup %{conn: conn, login_as: email} do
      user = insert(:user, email: email)
      event = insert(:event, %{user: user})

      # other user and event
      evil_user = insert(:user, %{first_name: "Mauricio", email: "666@999.pro"})

      evil_event =
        insert(:event, %{name: "we were doing well but things happened", user: evil_user})

      {:ok, jwt_string, _} = EVerApi.Accounts.token_sign_in(email, "123456")

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Bearer #{jwt_string}")

      {:ok, conn: conn, user: user, event: event, evil_user: evil_user, evil_event: evil_event}
    end

    # CREATE
    @tag individual_test: "speakers_create", login_as: "email@email.com"
    test "renders speaker when data is valid", %{conn: conn, user: user, event: event} do
      conn = post(conn, Routes.speaker_path(conn, :create, event.id), speaker: @create_attrs)
      response = json_response(conn, 201)["data"]

      assert %{
               "id" => speaker_id,
               "avatar" => "some avatar",
               "bio" => "some bio",
               "company" => "some company",
               "first_name" => "some first_name",
               "last_name" => "some last_name",
               "name" => "some name",
               "role" => "some role"
             } = response

      # check if event contains the speaker
      conn = get(conn, Routes.event_path(conn, :show, event.id))

      # event response
      %{"speakers" => speakers, "user" => resp_user} = json_response(conn, 200)["data"]

      # check the user
      assert resp_user["id"] == user.id

      resp = Enum.find(speakers, fn x -> x["id"] == speaker_id end)

      assert %{
               "id" => ^speaker_id,
               "avatar" => "some avatar",
               "bio" => "some bio",
               "company" => "some company",
               "first_name" => "some first_name",
               "last_name" => "some last_name",
               "name" => "some name",
               "role" => "some role"
             } = resp
    end

    @tag individual_test: "speakers_create", login_as: "email@email.com"
    test "renders errors when trying to add a speaker to non existent event", %{conn: conn} do
      conn = post(conn, Routes.speaker_path(conn, :create, "666"), speaker: @create_attrs)
      assert json_response(conn, 404)["errors"] != %{}
    end

    @tag individual_test: "speakers_create", login_as: "email@email.com"
    test "renders errors when data is invalid", %{conn: conn, event: event} do
      conn = post(conn, Routes.speaker_path(conn, :create, event.id), speaker: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag individual_test: "speakers_create", login_as: "email@email.com"
    test "renders 404 when trying to create a speaker for an event which belongs to another user",
         %{conn: conn, evil_event: evil_event} do
      conn = post(conn, Routes.speaker_path(conn, :create, evil_event.id), speaker: @create_attrs)
      assert json_response(conn, 404)["errors"] != %{}
    end

    # UPDATE
    @tag individual_test: "speakers_update", login_as: "email@email.com"
    test "renders updated speaker when data is valid", %{conn: conn, user: user, event: event} do
      %Speaker{id: speaker_id} = List.first(event.speakers)

      conn =
        put(conn, Routes.speaker_path(conn, :update, event.id, speaker_id), speaker: @update_attrs)

      assert %{
               "id" => speaker_id,
               "avatar" => "some updated avatar",
               "bio" => "some updated bio",
               "company" => "some updated company",
               "first_name" => "some updated first_name",
               "last_name" => "some updated last_name",
               "name" => "some updated name",
               "role" => "some updated role"
             } = json_response(conn, 200)["data"]

      # fetch event and check updated speaker
      conn = get(conn, Routes.event_path(conn, :show, event.id))

      # event response
      %{"speakers" => speakers, "user" => resp_user} = json_response(conn, 200)["data"]

      # check the user
      assert resp_user["id"] == user.id

      resp = Enum.find(speakers, fn x -> x["id"] == speaker_id end)

      assert %{
               "id" => ^speaker_id,
               "avatar" => "some updated avatar",
               "bio" => "some updated bio",
               "company" => "some updated company",
               "first_name" => "some updated first_name",
               "last_name" => "some updated last_name",
               "name" => "some updated name",
               "role" => "some updated role"
             } = resp
    end

    @tag individual_test: "speakers_update", login_as: "email@email.com"
    test "renders errors when update data is invalid", %{conn: conn, event: event} do
      %Speaker{id: id} = List.first(event.speakers)
      conn = put(conn, Routes.speaker_path(conn, :update, event.id, id), speaker: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag individual_test: "speakers_update", login_as: "email@email.com"
    test "renders errors when trying to update a speaker to non existent event", %{
      conn: conn,
      event: event
    } do
      %Speaker{id: speaker_id} = List.first(event.speakers)

      conn =
        put(conn, Routes.speaker_path(conn, :update, "666", speaker_id), speaker: @update_attrs)

      assert json_response(conn, 404)["errors"] != %{}
    end

    @tag individual_test: "speakers_update", login_as: "email@email.com"
    test "renders errors when trying to update non existent speaker for a valid event", %{
      conn: conn,
      event: event
    } do
      conn =
        put(conn, Routes.speaker_path(conn, :update, event.id, "999"), speaker: @update_attrs)

      assert json_response(conn, 404)["errors"] != %{}
    end

    @tag individual_test: "speakers_update", login_as: "email@email.com"
    test "render 404 when trying to update a speaker in event which belongs to another user", %{
      conn: conn,
      evil_event: evil_event
    } do
      %Speaker{id: speaker_id} = List.first(evil_event.speakers)

      conn =
        put(conn, Routes.speaker_path(conn, :update, evil_event.id, speaker_id),
          speaker: @update_attrs
        )

      assert json_response(conn, 404)["errors"] != %{}
    end

    # soft DELETE
    @tag individual_test: "speakers_delete", login_as: "email@email.com"
    test "deletes chosen speaker", %{conn: conn, user: user, event: event} do
      %Speaker{id: id} = List.first(event.speakers)

      conn = delete(conn, Routes.speaker_path(conn, :delete, event.id, id))
      assert response(conn, 204)
      assert Ever.get_speaker(id) == nil

      # check the event is not rendering the deleted speaker
      conn = get(conn, Routes.event_path(conn, :show, event.id))

      # event response
      %{"speakers" => speakers, "user" => resp_user} = json_response(conn, 200)["data"]

      # check the user
      assert resp_user["id"] == user.id

      resp = Enum.find(speakers, fn x -> x["id"] == id end)
      assert resp == nil

      # trying to re delete
      conn = delete(conn, Routes.speaker_path(conn, :delete, event.id, id))
      assert response(conn, 404)
    end

    @tag individual_test: "speakers_delete", login_as: "email@email.com"
    test "renders errors when trying to delete speaker to non existent event", %{
      conn: conn,
      event: event
    } do
      %Speaker{id: speaker_id} = List.first(event.speakers)
      conn = delete(conn, Routes.speaker_path(conn, :delete, "666", speaker_id))
      assert json_response(conn, 404)["errors"] != %{}
    end

    @tag individual_test: "speakers_delete", login_as: "email@email.com"
    test "renders errors when trying to delete non existen speaker for a valid event", %{
      conn: conn,
      event: event
    } do
      conn = delete(conn, Routes.speaker_path(conn, :delete, event.id, "999"))
      assert json_response(conn, 404)["errors"] != %{}
    end

    @tag individual_test: "speakers_delete", login_as: "email@email.com"
    test "renders errors when trying to delete a speaker which belongs to another event", %{
      conn: conn,
      event: event
    } do
      e = insert(:event, %{name: "foreign event"})
      s = insert(:speaker, %{event_id: e.id})
      conn = delete(conn, Routes.speaker_path(conn, :delete, event.id, s.id))
      assert json_response(conn, 404)["errors"] != %{}
    end

    @tag individual_test: "speakers_delete", login_as: "email@email.com"
    test "render 404 when trying to delete a speaker in event which belongs to another user", %{
      conn: conn,
      evil_event: evil_event
    } do
      %Speaker{id: speaker_id} = List.first(evil_event.speakers)
      conn = delete(conn, Routes.speaker_path(conn, :delete, evil_event.id, speaker_id))
      assert json_response(conn, 404)["errors"] != %{}
    end
  end

  # 401 Unauthorized
  @tag individual_test: "speakers_401"
  test "requires user authentication on all actions", %{conn: conn} do
    Enum.each(
      [
        post(conn, Routes.speaker_path(conn, :create, "666", %{})),
        put(conn, Routes.speaker_path(conn, :update, "666", "123", %{})),
        delete(conn, Routes.speaker_path(conn, :delete, "666", "234"))
      ],
      fn conn ->
        assert json_response(conn, 401)["message"] == "unauthenticated"
      end
    )
  end
end
