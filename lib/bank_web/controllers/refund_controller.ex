defmodule BankWeb.RefundController do
  use BankWeb, :controller

  import BankWeb.ResponseHelpers

  alias Bank.Refunds
  alias Bank.Refunds.Refund

  action_fallback BankWeb.FallbackController

  def create(conn, %{"payment_id" => payment_id, "refund" => refund_params}) do
    attrs = Map.put(refund_params, "payment_id", payment_id)

    with {:ok, %Refund{} = refund} <- Refunds.create(attrs) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.payment_refund_path(conn, :show, payment_id, refund))
      |> render("show.json", refund: refund)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        status_code = changeset_to_response_error(changeset)

        conn
        |> put_status(status_code)
        |> render("error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.json", refund: Refunds.get!(id))
  end
end
