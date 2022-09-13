defmodule BankWeb.RefundView do
  use BankWeb, :view
  alias BankWeb.RefundView

  def translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: translate_errors(changeset)}
  end

  def render("show.json", %{refund: refund}) do
    %{data: render_one(refund, RefundView, "refund.json")}
  end

  def render("refund.json", %{refund: refund}) do
    %{
      id: refund.id,
      payment_id: refund.payment_id,
      merchant_ref: refund.merchant_ref,
      amount: refund.amount
    }
  end
end
