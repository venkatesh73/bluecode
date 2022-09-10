defmodule Bank.Refunds.Refund do
  @moduledoc """
  Module and schema representing a refund.

  A refund is always tied to a specific payment record, but it is possible
  to make partial refunds (i.e. refund less than the total payment amount).
  In the same vein, it is possible to apply several refunds against the same
  payment record, the but sum of all refunded amounts for a given payment can
  never surpass the original payment amount.

  If a refund is persisted in the database, it is considered effective: the
  bank's client will have the money credited to their account.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Bank.Payments.Payment

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "refunds" do
    field :amount, :integer
    field :merchant_ref, :string

    belongs_to :payment, Payment, type: :binary_id

    timestamps()
  end

  @doc """
  Returns a changeset for given Refund and attributes to change.
  """
  @spec changeset(t(), attrs :: map) :: Ecto.Changeset.t()
  def changeset(refund, attrs) do
    refund
    |> cast(attrs, [:payment_id, :merchant_ref, :amount])
    |> validate_required([:payment_id, :merchant_ref, :amount])
    |> unique_constraint(:payment_id)
    |> unique_constraint(:merchant_ref)
    |> foreign_key_constraint(:payment_id)
  end
end
