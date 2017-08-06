defmodule Game.Account do
  @moduledoc """
  Handle database interactions for a user
  """

  alias Data.Repo
  alias Data.Config
  alias Data.User
  alias Data.Save

  @doc """
  Create a new user from attributes
  """
  @spec create(attributes :: map, save_attributes :: map) :: {:ok, User.t} | {:error, Ecto.Changeset.t}
  def create(attributes, %{class: class}) do
    save = Config.starting_save()
    |> Map.put(:stats, class.starting_stats())

    attributes = attributes
    |> Map.put(:class_id, class.id)
    |> Map.put(:save, save)

    case create_account(attributes) do
      {:ok, user} -> {:ok, user |> Repo.preload([:class])}
      anything -> anything
    end
  end

  defp create_account(attributes) do
    %User{}
    |> User.changeset(attributes)
    |> Repo.insert
  end

  @doc """
  Update the user's save
  """
  @spec save(User.t, Save.t) :: {:ok, User.t} | {:error, Ecto.Changeset.t}
  def save(user, save) do
    user
    |> User.changeset(%{save: save})
    |> Repo.update
  end
end
