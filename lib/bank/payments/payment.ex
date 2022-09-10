defmodule Bank.Payments.Payment do
  @moduledoc """
  Module and schema representing a payment.

  Once a payment has been persisted with an "approved" state, the merchant is guaranteed to
  receive money from the bank: they can therefore release the purchased goods to the customer.

  Other payment statuses:

  * processing: the payment is being processed, and it's state is unknown
  * declined: the payment was declined by the bank (e.g. insufficient funds)
  * failed: the payment was unable to complete (e.g. banking system crashed)
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Bank.Refunds.Refund

  @type t :: %__MODULE__{}
  @type status :: :processing | :approved | :declined | :failed

  @status [:processing, :approved, :declined, :failed]

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "payments" do
    field :amount, :integer
    field :merchant_ref, :string
    field :card_number, :string
    field :status, Ecto.Enum, values: @status

    has_many :refunds, Refund

    timestamps()
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:amount, :merchant_ref, :card_number, :status])
    |> validate_required([:amount, :merchant_ref, :card_number, :status])
    |> unique_constraint(:merchant_ref)
    |> unique_constraint(:card_number)
  end
end
