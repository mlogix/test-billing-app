class CreateAllocations < ActiveRecord::Migration[7.2]
  def change
    create_table :allocations do |t|
      t.references :subscription, null: false, foreign_key: true
      t.references :payment, null: false, foreign_key: true
      t.decimal :amount

      t.timestamps
    end
  end
end
