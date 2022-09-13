defmodule BankWeb.ResponseHelpers do
  @moduledoc """
  Response handler helps to parse the proper error status code and the message
  """
  @error_status_code %{
    "invalid amount" => :no_content,
    "negative amount" => :bad_request,
    "invalid_account_number" => :forbidden,
    "insufficient_funds" => :payment_required,
    "service_unavailable" => :service_unavailable,
    "internal_error" => :internal_server_error,
    "merchant with payment already associated" => :conflict,
    "card with payment already associated" => :unprocessable_entity,
    "payment doesn't exists" => :not_found
  }

  @spec changeset_to_response_error(Ecto.Changeset.t()) :: atom()
  def changeset_to_response_error(%Ecto.Changeset{} = changeset) do
    [error_msg | _] =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)
      |> Map.values()
      |> List.first()

    Map.get(@error_status_code, error_msg, :unprocessable_entity)
  end

  @spec error_msg_to_response_error(error_msg :: String.t()) :: atom()
  def error_msg_to_response_error(error_msg) do
    Map.get(@error_status_code, error_msg, :unprocessable_entity)
  end
end
