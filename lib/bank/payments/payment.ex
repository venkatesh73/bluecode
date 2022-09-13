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

  @card_number_format ~r/^\d{5,15}$/

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "payments" do
    field :amount, :integer
    field :merchant_ref, :string
    field :card_number, :string
    field :status, Ecto.Enum, values: @status, default: :processing

    has_many :refunds, Refund

    timestamps()
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:amount, :merchant_ref, :card_number, :status])
    |> validate_required([:amount, :merchant_ref, :card_number])
    |> validate_change(:amount, &amount_validator/2)
    |> validate_format(:card_number, @card_number_format, message: "invalid card_number")
    |> unique_constraint(:merchant_ref, message: "merchant with payment already associated")
    |> unique_constraint(:card_number, message: "card with payment already associated")
  end

  @spec declined_payment(Bank.Payments.Payment.t()) :: Ecto.Changeset.t()
  def declined_payment(%__MODULE__{} = payment), do: change(payment, status: :declined)

  @spec failed_payment(Bank.Payments.Payment.t()) :: Ecto.Changeset.t()
  def failed_payment(%__MODULE__{} = payment), do: change(payment, status: :failed)

  @spec approved_payment(Bank.Payments.Payment.t()) :: Ecto.Changeset.t()
  def approved_payment(%__MODULE__{} = payment), do: change(payment, status: :approved)

  defp amount_validator(_field, amount) do
    cond do
      amount == 0 ->
        [amount: "invalid amount"]

      amount < 0 ->
        [amount: "negative amount"]

      true ->
        []
    end
  end
end
