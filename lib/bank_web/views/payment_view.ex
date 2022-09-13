defmodule BankWeb.PaymentView do
  use BankWeb, :view
  alias BankWeb.PaymentView

  def translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: translate_errors(changeset)}
  end

  def render("data.json", %{payment: payment}) do
    %{
      data: %{
        merchant_ref: payment.merchant_ref,
        amount: payment.amount,
        card_number: payment.card_number,
        status: payment.status
      }
    }
  end

  def render("show.json", %{payment: payment}) do
    %{data: render_one(payment, PaymentView, "payment.json")}
  end

  def render("payment.json", %{payment: payment}) do
    %{
      id: payment.id,
      merchant_ref: payment.merchant_ref,
      amount: payment.amount,
      card_number: payment.card_number,
      status: payment.status
    }
  end
end
