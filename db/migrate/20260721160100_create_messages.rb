class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :conversation_session, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :messages, [:conversation_session_id, :created_at]
    add_index :messages, :role
  end
end
