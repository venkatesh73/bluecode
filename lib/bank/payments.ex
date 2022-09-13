defmodule Bank.Payments do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false
  alias Bank.Repo

  alias Bank.Payments.Payment

  @doc """
  Gets a single payment.

  Raises `Ecto.NoResultsError` if the Payment does not exist.

  ## Examples

      iex> get!(123)
      %Payment{}

      iex> get!(456)
      ** (Ecto.NoResultsError)

  """
  def get!(id), do: Repo.get!(Payment, id)

  @doc """
  Creates a payment.
  """
  def create(attrs \\ %{}) do
    %Payment{}
    |> Payment.changeset(attrs)
    |> Repo.insert()
  end

  def approve(payments) do
    payments
    |> Payment.approved_payment()
    |> Repo.update()
  end

  @spec get_payments_by_merchant(any) :: any
  def get_payments_by_merchant(merchant_ref) do
    query = from(p in Payment, where: p.merchant_ref == ^merchant_ref, lock: "FOR UPDATE")
    Repo.one(query)
  end

  @spec decline_payments_by_merchant(any) :: any
  def decline_payments_by_merchant(merchant_ref) do
    case get_payments_by_merchant(merchant_ref) do
      nil ->
        {:error, :payment_not_found}

      %Payment{} = payment ->
        payment
        |> Payment.declined_payment()
        |> Repo.update()
    end
  end

  @spec failed_payments_by_merchant(any) :: any
  def failed_payments_by_merchant(merchant_ref) do
    case get_payments_by_merchant(merchant_ref) do
      nil ->
        {:error, :payment_not_found}

      %Payment{} = payment ->
        payment
        |> Payment.failed_payment()
        |> Repo.update()
    end
  end
end
