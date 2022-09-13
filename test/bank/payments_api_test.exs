defmodule Bank.PaymentsApiTest do
  use Bank.DataCase

  import Mox

  alias Bank.FakeCardNumber
  alias Bank.PaymentsApi
  alias Bank.Payments.Payment
  alias Bank.MockAccountsService, as: Service

  setup :verify_on_exit!

  describe "create/1" do
    test "returns {:ok, payments} on valid payments" do
      expect(Service, :place_hold, fn _account_number, _amount -> {:ok, %{}} end)

      merchant_ref = Ecto.UUID.generate()

      valid_attrs = %{
        amount: "1205",
        merchant_ref: merchant_ref,
        card_number: FakeCardNumber.generate()
      }

      assert {:ok, %Payment{merchant_ref: ^merchant_ref, amount: 1205, status: :approved}} =
               PaymentsApi.create(valid_attrs)
    end

    test "returns {:error, Ecto.Changeset.t()} on invalid payments" do
      merchant_ref = Ecto.UUID.generate()

      invalid_attrs = %{
        amount: "1205",
        merchant_ref: merchant_ref,
        card_number: "abceddrefegege"
      }

      assert {:error, %Ecto.Changeset{}} = PaymentsApi.create(invalid_attrs)
    end

    test "returns {:error, :insufficient_funds} when insufficient funds" do
      expect(Service, :place_hold, fn _account_number, _amount ->
        {:error, :insufficient_funds}
      end)

      valid_attrs = %{
        "amount" => "1025",
        "merchant_ref" => Ecto.UUID.generate(),
        "card_number" => FakeCardNumber.generate()
      }

      assert {:error, :insufficient_funds, _} = PaymentsApi.create(valid_attrs)
    end

    test "returns {:error, :invalid_account_number} when invalid account number" do
      expect(Service, :place_hold, fn _account_number, _amount ->
        {:error, :invalid_account_number}
      end)

      invalid_attrs = %{
        "amount" => "1025",
        "merchant_ref" => Ecto.UUID.generate(),
        "card_number" => FakeCardNumber.generate()
      }

      assert {:error, :invalid_account_number, _} = PaymentsApi.create(invalid_attrs)
    end

    test "returns {:error, :service_unavailable} when account services is unavailable" do
      expect(Service, :place_hold, fn _account_number, _amount ->
        {:error, :service_unavailable}
      end)

      valid_attrs = %{
        "amount" => "1025",
        "merchant_ref" => Ecto.UUID.generate(),
        "card_number" => FakeCardNumber.generate()
      }

      assert {:error, :service_unavailable, _} = PaymentsApi.create(valid_attrs)
    end

    test "returns {:error, :internal_error} when account service is not running" do
      expect(Service, :place_hold, fn _account_number, _amount -> {:error, :internal_error} end)

      valid_attrs = %{
        "amount" => "1025",
        "merchant_ref" => Ecto.UUID.generate(),
        "card_number" => FakeCardNumber.generate()
      }

      assert {:error, :internal_error, _} = PaymentsApi.create(valid_attrs)
    end
  end
end
