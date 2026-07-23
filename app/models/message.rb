class Message < ApplicationRecord
  ROLES = %w[user assistant system].freeze

  belongs_to :conversation_session, touch: true
  has_one_attached :audio

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :content, presence: true

  scope :chronological, -> { order(:created_at, :id) }

  def user?
    role == "user"
  end

  def assistant?
    role == "assistant"
  end
end
