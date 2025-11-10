class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.string :title
      t.string :status, null: false, default: 'waiting'
      t.references :initiator_id,
        null: false,
        foreign_key: { to_table: :users }

      t.bigint :assigned_expert_id, null: false
        t.references :assigned_expert_id,
               null: true,
               foreign_key: { to_table: :users }

      t.datetime :last_message_at
      t.datetime :created_at
      t.datetime :updated_at

      t.timestamps
    end

    add_foreign_key :conversations, :users, column: :initiator_id
    add_foreign_key :conversations, :users, column: :assigned_expert_id
  end
end
