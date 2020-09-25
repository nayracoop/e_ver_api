defmodule EVerApi.Ever.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :name, :string
    field :description, :string
    field :summary, :string
    field :url, :string
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime

    belongs_to :user, EVerApi.Accounts.User
    has_many :talks, EVerApi.Ever.Talk
    has_many :sponsors, EVerApi.Ever.Sponsor

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :details, :summary, :url, :start_time, :end_time, :user_id])
    |> validate_required([:name, :description, :start_time, :end_time, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
