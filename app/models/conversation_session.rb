class ConversationSession < ApplicationRecord
  has_many :messages, dependent: :destroy

  validates :title, presence: true

  scope :recent, -> { order(updated_at: :desc) }

  def display_title
    title.presence || "New conversation"
  end
end
