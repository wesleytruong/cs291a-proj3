class ExpertAssignment < ApplicationRecord
  enum :status, { active: "active", resolved: "resolved", unclaimed: "unclaimed" }

  # Associations
  belongs_to :conversation
  belongs_to :expert, class_name: "ExpertProfile"

  # Validations
  validates :status, presence: true
  validates :assigned_at, presence: true

  # Callbacks
  before_create :set_assigned_at

  private

  def set_assigned_at
    self.assigned_at = Time.current if assigned_at.blank?
  end
end
