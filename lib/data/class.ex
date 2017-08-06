defmodule Data.Class do
  use Data.Schema

  alias Data.Stats

  schema "classes" do
    field :name, :string
    field :description, :string
    field :starting_stats, Stats
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :starting_stats])
    |> validate_required([:name, :description, :starting_stats])
    |> validate_stats()
  end

  defp validate_stats(changeset) do
    case changeset do
      %{changes: %{starting_stats: stats}} when stats != nil ->
        _validate_stats(changeset)
      _ -> changeset
    end
  end

  defp _validate_stats(changeset = %{changes: %{starting_stats: stats}}) do
    case Stats.valid_character?(stats) do
      true -> changeset
      false -> add_error(changeset, :starting_stats, "is invalid")
    end
  end
end
