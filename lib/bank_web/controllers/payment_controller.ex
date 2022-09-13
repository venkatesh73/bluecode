defmodule BankWeb.PaymentController do
  use BankWeb, :controller

  import BankWeb.ResponseHelpers

  alias Bank.Payments
  alias Bank.Payments.Payment
  alias Bank.PaymentsApi

  action_fallback BankWeb.FallbackController

  def create(conn, %{"payment" => payment_params}) do
    with {:ok, %Payment{} = payment} <- PaymentsApi.create(payment_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.payment_path(conn, :show, payment))
      |> render("show.json", payment: payment)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        status_code = changeset_to_response_error(changeset)

        conn
        |> put_status(status_code)
        |> render("error.json", changeset: changeset)

      {:error, error_msg, payments} ->
        status_code = error_msg_to_response_error(to_string(error_msg))

        conn
        |> put_status(status_code)
        |> render("data.json", payment: payments)
    end
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", payment: Payments.get!(id))
  end
end
