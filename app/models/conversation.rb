class Conversation < ApplicationRecord
  enum status: { waiting: "waiting", active: "active", closed: "closed" }

  # Associations
  belongs_to :initiator, class_name: "User"
  belongs_to :assigned_expert, class_name: "User", optional: true
  has_many :messages, dependent: :destroy
  has_many :expert_assignments, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :status, presence: true

  # Callbacks
  after_create :set_waiting_status

  def unread_count_for_user(user)
    messages.where.not(sender_id: user.id).where(is_read: false).count
  end

  private

  def set_waiting_status
    self.status = "waiting" if status.blank?
  end
end
