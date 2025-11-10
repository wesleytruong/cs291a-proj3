class User < ApplicationRecord
  has_secure_password

  # Associations
  has_many :initiated_conversations, class_name: "Conversation", foreign_key: :initiator_id, dependent: :destroy
  has_many :assigned_conversations, class_name: "Conversation", foreign_key: :assigned_expert_id, dependent: :nullify
  has_many :messages, foreign_key: :sender_id, dependent: :destroy
  has_one :expert_profile, dependent: :destroy

  # Validations
  validates :username, presence: true, uniqueness: true
  validates :email, presence: true
  validates :password, presence: true, on: :create

  # Callbacks
  before_validation :set_default_email, on: :create

  private

  def set_default_email
    self.email = "#{username}@example.com" if email.blank? && username.present?
  end
end
