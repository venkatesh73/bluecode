defmodule Bank.PaymentsApi do
  @moduledoc false
  alias Bank.Accounts.Service
  alias Bank.Payments
  alias Bank.Payments.Payment

  @spec create(params :: map()) ::
          {:ok, Payment.t()}
          | {:error, Ecto.Changeset.t() | String.t()}
          | {:error, String.t(), map() | Payment.t()}
  def create(params) do
    with {:ok, %Payment{} = payment} <- Payments.create(params),
         {:ok, _} <- Service.place_hold(payment.card_number, payment.amount) do
      Payments.approve(payment)
    else
      {:error, error} when is_atom(error) ->
        update_payment_status(params, error)

      error ->
        error
    end
  end

  defp update_payment_status(params, error)
       when error in [:insufficient_funds, :invalid_account_number] do
    case Payments.decline_payments_by_merchant(params["merchant_ref"]) do
      {:ok, payments} ->
        {:error, error, payments}

      {:error, :payment_not_found} ->
        {:error, :payment_not_found, params}
    end
  end

  defp update_payment_status(params, error)
       when error in [:service_unavailable, :internal_error] do
    case Payments.failed_payments_by_merchant(params["merchant_ref"]) do
      {:ok, payments} ->
        {:error, error, payments}

      {:error, :payment_not_found} ->
        {:error, :payment_not_found, params}
    end
  end
end
