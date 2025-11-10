class ExpertProfile < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :expert_assignments, foreign_key: :expert_id, dependent: :destroy
  has_many :conversations, through: :expert_assignments

  # Validations
  validates :user_id, uniqueness: true
end
