defmodule Bank.Accounts.Service do
  @moduledoc """
  Client to interact with a remote service to interact with customer accounts.
  """

  @type place_hold_error ::
          :insufficient_funds
          | :invalid_account_number
          | :internal_error
          | common_errors()
  @type hold_ref_error :: :invalid_hold_reference | common_errors()
  @type common_errors :: :service_unavailable
  @opaque hold_ref :: Bank.Accounts.HoldReference.t()

  @doc """
  Places a hold on the account.

  Reduces the `account_number` account's actual balance by `amount`.
  """
  @callback place_hold(Bank.account_number(), Bank.amount()) ::
              {:ok, hold_ref} | {:error, place_hold_error}

  @doc """
  Releases a hold on the account.

  Increases the `account_number` account's actual balance by the amount previously held.
  """
  @callback release_hold(hold_ref()) :: :ok | {:error, hold_ref_error}

  @doc """
  Withdraws the held money from the account.

  Decreases the `account_number` account's current balance by the amount previously held.
  The hold on the customer's funds is implicitly release atomically.
  """
  @callback withdraw_funds(hold_ref()) :: :ok | {:error, hold_ref_error}

  @spec place_hold(Bank.account_number(), Bank.amount()) ::
          {:ok, hold_ref} | {:error, place_hold_error}
  def place_hold(account_number, amount), do: impl().place_hold(account_number, amount)

  @spec release_hold(hold_ref()) :: :ok | {:error, hold_ref_error}
  def release_hold(hold_ref), do: impl().release_hold(hold_ref)

  @spec withdraw_funds(hold_ref()) :: :ok | {:error, hold_ref_error}
  def withdraw_funds(hold_ref), do: impl().withdraw_funds(hold_ref)

  defp impl, do: Application.fetch_env!(:bank, :accounts_service)
end
