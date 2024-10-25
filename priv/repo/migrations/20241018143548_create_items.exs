defmodule Gregslist.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :item_name, :string
      add :desc, :string
      add :price, :float
      add :location, :string
      add :art_image, :string

      timestamps(type: :utc_datetime)
    end
  end
end
