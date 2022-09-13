defmodule Bank.Repo.Migrations.AlterRefundsWithConstraint do
  use Ecto.Migration

  def change do
    execute(
      """
        ALTER TABLE refunds ADD CONSTRAINT can_perform_refund_from_payments CHECK(refund_payments_amount_guard(payment_id) >= amount);
      """,
      "ALTER TABLE public.refunds DROP CONSTRAINT can_perform_refund_from_payments;"
    )
  end
end
