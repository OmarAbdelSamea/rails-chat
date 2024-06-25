class CreateMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :messages, primary_key: [:application_token, :chat_number, :number] do |t|
      t.integer :number, null: false
      t.string :content, null: false
      t.string :application_token, null: false
      t.integer :chat_number, null: false

      t.timestamps
    end
  end
end
