class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :username, null: false
      t.string :email, null: false
      t.string :password_digest
      t.datetime :last_active_at
      t.datetime :created_at
      t.datetime :updated_at

      t.timestamps
    end

    add_index :users, :username, unique: true
  end
end
