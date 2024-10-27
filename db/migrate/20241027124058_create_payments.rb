class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :subscription
      t.timestamp :charge_on
      t.boolean :partial
      t.references :initial_payment
      t.decimal :amount

      t.boolean :succeed
      t.timestamp :charged_at
      t.json :gateway_response

      t.timestamps
    end
  end
end
