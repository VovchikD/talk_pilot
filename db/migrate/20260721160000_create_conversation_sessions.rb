class CreateConversationSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :conversation_sessions do |t|
      t.string :title, null: false, default: "New conversation"
      t.string :topic
      t.string :level
      t.text :summary

      t.timestamps
    end
  end
end
