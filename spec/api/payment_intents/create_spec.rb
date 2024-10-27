# frozen_string_literal: true

require "rails_helper"

describe "POST /payment_intents" do
  let(:subscription) do
    create :subscription
  end

  let(:params) do
    {
      subscription_id: subscription.id,
      amount: 100.0
    }
  end

  let(:success_response) do
    PaymentGateway::PaymentGatewayResponse.new(status: PaymentGateway::StatusCodes::SUCCESS)
  end

  let(:failure_response) do
    PaymentGateway::PaymentGatewayResponse.new(status: PaymentGateway::StatusCodes::FAILURE)
  end

  let(:insufficient_funds_response) do
    PaymentGateway::PaymentGatewayResponse.new(status: PaymentGateway::StatusCodes::INSUFFICIENT_FUNDS)
  end

  subject(:payment_intent) do
    post "/payment_intents",
         params: {
           payment: params
         }
  end

  context "when successful payment" do
    before do
      allow_any_instance_of(PaymentGateway::MockServerService).to(
        receive(:charge).with(100.0).and_return(success_response)
      )
    end

    it "creates successful payment" do
      payment_intent

      result = JSON.parse(response.body, symbolize_names: true)

      expect(response.status).to eq 200
      expect(result.dig(:payment, :succeed)).to eq true
      expect(result.dig(:payment, :amount).to_f).to eq params[:amount].to_f
      expect(result.dig(:payment, :partial)).to eq false
      expect(result.dig(:payment, :gateway_response)).to match(status: "success")
    end

    it "creates payment and allocation records" do
      expect { payment_intent }.to(
        change { Payment.count }.by(1).and(
          change { Allocation.count }.by(1)
        )
      )
    end
  end

  context "when failed payment" do
    before do
      allow_any_instance_of(PaymentGateway::MockServerService).to(
        receive(:charge).with(100.0).and_return(failure_response)
      )
    end

    it "creates failed payment" do
      payment_intent

      result = JSON.parse(response.body, symbolize_names: true)
      expect(response.status).to eq 409
      expect(result.dig(:payment, :succeed)).to eq false
    end

    it "creates failed payment without allocation" do
      expect { payment_intent }.to(
        change { Payment.count }.by(1).and(
          change { Allocation.count }.by(0)
        )
      )
    end
  end

  context "when insufficient_funds" do

    context "with 75% of amount" do
      before do
        allow_any_instance_of(PaymentGateway::MockServerService).to(
          receive(:charge).with(100.0).and_return(insufficient_funds_response)
        )

        allow_any_instance_of(PaymentGateway::MockServerService).to(
          receive(:charge).with(75.0).and_return(success_response)
        )
      end

      it "succeed initial payment" do
        payment_intent

        result = JSON.parse(response.body, symbolize_names: true)
        expect(response.status).to eq 200
        expect(result.dig(:payment, :succeed)).to eq true
        expect(result.dig(:payment, :partial)).to eq true
        expect(result.dig(:payment, :amount).to_f).to eq 75.0
        expect(result.dig(:payment, :gateway_response)).to match(status: "success")
      end

      it "succeed scheduled payment" do
        payment_intent

        result = JSON.parse(response.body, symbolize_names: true)
        initial_payment_id = result.dig(:payment, :id)

        scheduled_payment = Payment.find_by(initial_payment_id: initial_payment_id)
        expect(scheduled_payment).to be_present

        expect(scheduled_payment.amount).to eq 25.0
        expect(scheduled_payment.charge_on).to eq scheduled_payment.initial_payment.charged_at + 1.week
        expect(scheduled_payment.partial).to eq true
        expect(scheduled_payment.charged_at).to be_nil
      end

      it "creates payment with allocation and scheduled remained" do
        expect { payment_intent }.to(
          change { Payment.count }.by(2).and(
            change { Allocation.count }.by(1)
          )
        )
      end
    end

    context "with 50% of amount" do
      before do
        allow_any_instance_of(PaymentGateway::MockServerService).to(
          receive(:charge).with(100.0).and_return(insufficient_funds_response)
        )

        allow_any_instance_of(PaymentGateway::MockServerService).to(
          receive(:charge).with(75.0).and_return(insufficient_funds_response)
        )

        allow_any_instance_of(PaymentGateway::MockServerService).to(
          receive(:charge).with(50.0).and_return(success_response)
        )
      end

      it "succeed initial payment" do
        payment_intent

        result = JSON.parse(response.body, symbolize_names: true)
        expect(response.status).to eq 200
        expect(result.dig(:payment, :succeed)).to eq true
        expect(result.dig(:payment, :partial)).to eq true
        expect(result.dig(:payment, :amount).to_f).to eq 50.0
        expect(result.dig(:payment, :gateway_response)).to match(status: "success")
      end

      it "succeed scheduled payment" do
        payment_intent

        result = JSON.parse(response.body, symbolize_names: true)
        initial_payment_id = result.dig(:payment, :id)

        scheduled_payment = Payment.find_by(initial_payment_id: initial_payment_id)
        expect(scheduled_payment).to be_present

        expect(scheduled_payment.amount).to eq 50.0
        expect(scheduled_payment.charge_on).to eq scheduled_payment.initial_payment.charged_at + 1.week
        expect(scheduled_payment.partial).to eq true
        expect(scheduled_payment.charged_at).to be_nil
      end

      it "creates payment with allocation and scheduled remained" do
        expect { payment_intent }.to(
          change { Payment.count }.by(2).and(
            change { Allocation.count }.by(1)
          )
        )
      end
    end

    context "with 25% of amount" do
      before do
        allow_any_instance_of(PaymentGateway::MockServerService).to(
          receive(:charge).with(100.0).and_return(insufficient_funds_response)
        )

        allow_any_instance_of(PaymentGateway::MockServerService).to(
          receive(:charge).with(75.0).and_return(insufficient_funds_response)
        )

        allow_any_instance_of(PaymentGateway::MockServerService).to(
          receive(:charge).with(50.0).and_return(insufficient_funds_response)
        )

        allow_any_instance_of(PaymentGateway::MockServerService).to(
          receive(:charge).with(25.0).and_return(success_response)
        )
      end

      it "succeed initial payment" do
        payment_intent

        result = JSON.parse(response.body, symbolize_names: true)
        expect(response.status).to eq 200
        expect(result.dig(:payment, :succeed)).to eq true
        expect(result.dig(:payment, :partial)).to eq true
        expect(result.dig(:payment, :amount).to_f).to eq 25.0
        expect(result.dig(:payment, :gateway_response)).to match(status: "success")
      end

      it "succeed scheduled payment" do
        payment_intent

        result = JSON.parse(response.body, symbolize_names: true)
        initial_payment_id = result.dig(:payment, :id)

        scheduled_payment = Payment.find_by(initial_payment_id: initial_payment_id)
        expect(scheduled_payment).to be_present

        expect(scheduled_payment.amount).to eq 75.0
        expect(scheduled_payment.charge_on).to eq scheduled_payment.initial_payment.charged_at + 1.week
        expect(scheduled_payment.partial).to eq true
        expect(scheduled_payment.charged_at).to be_nil
      end

      it "creates payment with allocation and scheduled remained" do
        expect { payment_intent }.to(
          change { Payment.count }.by(2).and(
            change { Allocation.count }.by(1)
          )
        )
      end
    end

    context "with totally insufficient_funds" do
      before do
        allow_any_instance_of(PaymentGateway::MockServerService).to(
          receive(:charge).with(100.0).and_return(insufficient_funds_response)
        )

        allow_any_instance_of(PaymentGateway::MockServerService).to(
          receive(:charge).with(75.0).and_return(insufficient_funds_response)
        )

        allow_any_instance_of(PaymentGateway::MockServerService).to(
          receive(:charge).with(50.0).and_return(insufficient_funds_response)
        )

        allow_any_instance_of(PaymentGateway::MockServerService).to(
          receive(:charge).with(25.0).and_return(insufficient_funds_response)
        )
      end

      it "payment respond with insufficient_funds error" do
        payment_intent

        result = JSON.parse(response.body, symbolize_names: true)
        expect(response.status).to eq 200
        expect(result.dig(:status)).to eq "insufficient_funds"
        expect(result.dig(:error, :message)).to eq "Insufficient funds"
      end

      it "rescheduled new payment in a week" do
        payment_intent

        result = JSON.parse(response.body, symbolize_names: true)
        initial_payment_id = result.dig(:payment, :id)

        scheduled_payment = Payment.find_by(initial_payment_id: initial_payment_id)
        expect(scheduled_payment).to be_present

        expect(scheduled_payment.amount).to eq 100.0
        expect(scheduled_payment.charge_on).to eq scheduled_payment.initial_payment.charge_on + 1.week
        expect(scheduled_payment.partial).to eq false
        expect(scheduled_payment.charged_at).to be_nil
      end

      it "creates payment with allocation and rescheduled remained" do
        expect { payment_intent }.to(
          change { Payment.count }.by(2).and(
            change { Allocation.count }.by(0)
          )
        )
      end
    end


  end
end
