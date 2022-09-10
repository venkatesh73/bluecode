defmodule BankWeb.PaymentController do
  use BankWeb, :controller

  alias Bank.Payments
  alias Bank.Payments.Payment

  action_fallback BankWeb.FallbackController

  def create(conn, %{"payment" => payment_params}) do
    with {:ok, %Payment{} = payment} <- Payments.create(payment_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.payment_path(conn, :show, payment))
      |> render("show.json", payment: payment)
    end
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", payment: Payments.get!(id))
  end
end
