defmodule BankWeb.PaymentControllerTest do
  use BankWeb.ConnCase

  import Mox

  import Bank.PaymentsFixtures

  alias Bank.FakeCardNumber
  alias Bank.Payments
  alias Bank.Payments.Payment

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  @invalid_attrs %{amount: nil, merchant_ref: nil, card_number: ""}

  defp create_attrs(attrs \\ %{}) do
    Map.merge(
      %{
        amount: "1205",
        card_number: FakeCardNumber.generate(),
        merchant_ref: Ecto.UUID.generate(),
        status: "approved"
      },
      attrs
    )
  end

  setup %{conn: conn} do
    Mox.stub_with(Bank.MockAccountsService, Bank.Accounts.DummyService)
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create payment" do
    test "renders payment when data is valid", %{conn: conn} do
      payment_attrs = create_attrs()
      conn = post(conn, Routes.payment_path(conn, :create), payment: payment_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.payment_path(conn, :show, id))

      merchant_ref = payment_attrs.merchant_ref

      assert %{
               "id" => ^id,
               "amount" => 1205,
               "merchant_ref" => ^merchant_ref,
               "status" => "approved"
             } = json_response(conn, 200)["data"]
    end

    test "creates 'declined' payment and 402 response on insufficient funds", %{conn: conn} do
      Bank.MockAccountsService
      |> expect(:place_hold, fn _account_number, _amount -> {:error, :insufficient_funds} end)

      payment_attrs = create_attrs()
      conn = post(conn, Routes.payment_path(conn, :create), payment: payment_attrs)

      merchant_ref = payment_attrs.merchant_ref

      assert %{
               "amount" => 1205,
               "merchant_ref" => ^merchant_ref,
               "status" => "declined"
             } = json_response(conn, 402)["data"]

      assert %Payment{status: :declined} = Payments.get_payments_by_merchant(merchant_ref)
    end

    test "creates 'declined' payment and 403 response on invalid account number", %{conn: conn} do
      Bank.MockAccountsService
      |> expect(:place_hold, fn _account_number, _amount -> {:error, :invalid_account_number} end)

      payment_attrs = create_attrs()
      conn = post(conn, Routes.payment_path(conn, :create), payment: payment_attrs)

      merchant_ref = payment_attrs.merchant_ref

      assert %{
               "amount" => 1205,
               "merchant_ref" => ^merchant_ref,
               "status" => "declined"
             } = json_response(conn, 403)["data"]

      assert %Payment{status: :declined} = Payments.get_payments_by_merchant(merchant_ref)
    end

    test "creates 'failed' payment and 503 response when account service service unavailable", %{
      conn: conn
    } do
      Bank.MockAccountsService
      |> expect(:place_hold, fn _account_number, _amount -> {:error, :service_unavailable} end)

      payment_attrs = create_attrs()
      conn = post(conn, Routes.payment_path(conn, :create), payment: payment_attrs)

      merchant_ref = payment_attrs.merchant_ref

      assert %{
               "amount" => 1205,
               "merchant_ref" => ^merchant_ref,
               "status" => "failed"
             } = json_response(conn, 503)["data"]

      assert %Payment{status: :failed} = Payments.get_payments_by_merchant(merchant_ref)
    end

    test "creates 'failed' payment and 500 response when account service internal server error",
         %{conn: conn} do
      Bank.MockAccountsService
      |> expect(:place_hold, fn _account_number, _amount -> {:error, :internal_error} end)

      payment_attrs = create_attrs()
      conn = post(conn, Routes.payment_path(conn, :create), payment: payment_attrs)

      merchant_ref = payment_attrs.merchant_ref

      assert %{
               "amount" => 1205,
               "merchant_ref" => ^merchant_ref,
               "status" => "failed"
             } = json_response(conn, 500)["data"]

      assert %Payment{status: :failed} = Payments.get_payments_by_merchant(merchant_ref)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.payment_path(conn, :create), payment: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "returns 204 if amount is 0", %{conn: conn} do
      payment_attrs = create_attrs(%{amount: 0})
      conn = post(conn, Routes.payment_path(conn, :create), payment: payment_attrs)
      assert response(conn, 204)
    end

    test "returns 422 if card_number isn't unique", %{conn: conn} do
      card_number = FakeCardNumber.generate()

      payment_attrs = create_attrs(%{card_number: card_number})
      payment_fixture(payment_attrs)

      payment_attrs = create_attrs(%{card_number: card_number})
      conn = post(conn, Routes.payment_path(conn, :create), payment: payment_attrs)

      assert Enum.member?(
               json_response(conn, 422)["errors"]["card_number"],
               "card with payment already associated"
             )
    end

    test "returns 409 if merchant_ref is already associated with payment", %{conn: conn} do
      payment_attrs = create_attrs()
      payment_fixture(payment_attrs)

      payment_attrs = create_attrs(%{merchant_ref: payment_attrs.merchant_ref})
      conn = post(conn, Routes.payment_path(conn, :create), payment: payment_attrs)

      assert Enum.member?(
               json_response(conn, 409)["errors"]["merchant_ref"],
               "merchant with payment already associated"
             )
    end

    test "returns 400 if amount is negative", %{conn: conn} do
      payment_attrs = create_attrs(%{amount: -1204})
      conn = post(conn, Routes.payment_path(conn, :create), payment: payment_attrs)
      assert response(conn, 400)
    end

    test "returns 422 if card number is invalid", %{conn: conn} do
      payment_attrs = create_attrs(%{card_number: "wedasdfidfmllkdgjjkjg"})
      conn = post(conn, Routes.payment_path(conn, :create), payment: payment_attrs)
      assert response(conn, 422)
    end
  end
end
