defmodule Bank.PaymentsTest do
  use Bank.DataCase

  import Bank.PaymentsFixtures

  alias Bank.FakeCardNumber
  alias Bank.Payments
  alias Bank.Payments.Payment

  @invalid_attrs %{amount: nil, merchant_ref: nil}

  test "get!/1 returns the payment with given id" do
    payment = payment_fixture()
    assert Payments.get!(payment.id) == payment
  end

  test "create/1 with valid data creates a payment" do
    merchant_ref = Ecto.UUID.generate()

    valid_attrs = %{
      amount: "1205",
      merchant_ref: merchant_ref,
      card_number: FakeCardNumber.generate(),
      status: "approved"
    }

    assert {:ok, %Payment{merchant_ref: ^merchant_ref, amount: 1205}} =
             Payments.create(valid_attrs)
  end

  test "create/1 with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = Payments.create(@invalid_attrs)
  end

  test "create/1 with negative amounts returns :negative_amount error " do
    attrs = %{
      amount: "-1205",
      merchant_ref: Ecto.UUID.generate(),
      card_number: FakeCardNumber.generate()
    }

    assert {:error, %Ecto.Changeset{errors: [amount: {"negative amount", _}]}} =
             Payments.create(attrs)
  end

  test "create/1 with 0 amounts returns :invalid_amount error " do
    attrs = %{
      amount: "0",
      merchant_ref: Ecto.UUID.generate(),
      card_number: FakeCardNumber.generate()
    }

    assert {:error, %Ecto.Changeset{errors: [amount: {"invalid amount", _}]}} =
             Payments.create(attrs)
  end

  test "create/1 with invalid card number returns :invalid_card_number error " do
    attrs = %{
      amount: "1205",
      merchant_ref: Ecto.UUID.generate(),
      card_number: "123"
    }

    assert {:error, %Ecto.Changeset{errors: [card_number: {"invalid card_number", _}]}} =
             Payments.create(attrs)
  end
end
