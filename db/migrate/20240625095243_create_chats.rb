class CreateChats < ActiveRecord::Migration[5.2]
  def change
    create_table :chats, primary_key: [:application_token, :number] do |t|
      t.integer :number, null: false
      t.integer :messages_count, default: 0
      t.string :application_token, null: false

      t.timestamps
    end

    add_foreign_key :chats, :applications, column: :application_token, primary_key: "token"
  end
end
