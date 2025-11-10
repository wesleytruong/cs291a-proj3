class Message < ApplicationRecord
  enum sender_role: { initiator: "initiator", expert: "expert" }

  # Associations
  belongs_to :conversation
  belongs_to :sender, class_name: "User"

  # Validations
  validates :content, presence: true
  validates :sender_role, presence: true

  # Callbacks
  after_create_commit :touch_conversation_last_message_at

  scope :unread, -> { where(is_read: false) }

  private

  def touch_conversation_last_message_at
    conversation.touch(:last_message_at)
  end
end
