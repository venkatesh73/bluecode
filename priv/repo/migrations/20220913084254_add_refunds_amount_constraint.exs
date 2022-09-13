defmodule Bank.Repo.Migrations.AddRefundsAmountConstraint do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    execute(
      """
      CREATE OR REPLACE FUNCTION refund_payments_amount_guard(_id uuid) RETURNS BIGINT AS
      $$
        BEGIN
          RETURN (
            select
              sum(abs(refunds_sum.total_amount - payments_sum.total_amount))
              from (
                select coalesce(sum(amount), 100000) total_amount from payments p where p.id = $1
              ) payments_sum
              full outer join (
                select coalesce(sum(amount), 0) as total_amount from refunds r where r.payment_id = $1
              ) refunds_sum
            on 1 = 1
          );
        END;
      $$ LANGUAGE PLpgSQL;
      """,
      "DROP FUNCTION IF EXISTS refund_payments_amount_guard CASCADE;"
    )
  end
end
