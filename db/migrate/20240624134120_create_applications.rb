class CreateApplications < ActiveRecord::Migration[5.2]
  def change
    create_table :applications, primary_key: [:token] do |t|
      t.string :token, unique: true, index: false, null: false
      t.string :name, null: false
      t.integer :chats_count, default: 0

      t.timestamps
    end
  end
end
