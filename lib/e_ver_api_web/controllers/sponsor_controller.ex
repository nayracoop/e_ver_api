defmodule EVerApiWeb.SponsorController do
  use EVerApiWeb, :controller

  alias EVerApi.Sponsors
  alias EVerApi.Sponsors.Sponsor
  alias EVerApi.Ever

  action_fallback EVerApiWeb.FallbackController

  # def index(conn, _params) do
  #   sponsors = Sponsors.list_sponsors()
  #   render(conn, "index.json", sponsors: sponsors)
  # end

  def create(conn, %{"event_id" => event_id, "sponsor" => sponsor_params}) do

    case Ever.get_event(event_id) do
      nil -> {:error, :not_found}
      event ->
        params = Map.put_new(sponsor_params, "event_id", event.id)
        with {:ok, %Sponsor{} = sponsor} <- Sponsors.create_sponsor(params) do

          conn
          |> put_status(:created)
          |> render("show.json", sponsor: sponsor)
        end
    end
  end

  # def show(conn, %{"id" => id}) do
  #   sponsor = Sponsors.get_sponsor!(id)
  #   render(conn, "show.json", sponsor: sponsor)
  # end

  def update(conn, %{"id" => id, "sponsor" => sponsor_params}) do
    sponsor = Sponsors.get_sponsor!(id)

    with {:ok, %Sponsor{} = sponsor} <- Sponsors.update_sponsor(sponsor, sponsor_params) do
      render(conn, "show.json", sponsor: sponsor)
    end
  end

  def delete(conn, %{"id" => id}) do
    sponsor = Sponsors.get_sponsor!(id)

    with {:ok, %Sponsor{}} <- Sponsors.delete_sponsor(sponsor) do
      send_resp(conn, :no_content, "")
    end
  end
end
