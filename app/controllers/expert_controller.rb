class ExpertController < ApplicationController
  before_action :authenticate_with_jwt!
  before_action :ensure_expert_profile, except: [ :profile ]
  before_action :set_conversation, only: [ :claim, :unclaim ]

  def queue
    waiting_conversations = Conversation.where(status: "waiting", assigned_expert_id: nil)
                                        .includes(:initiator, :messages)

    assigned_conversations = current_user.assigned_conversations
                                         .where(status: "active")
                                         .includes(:initiator, :messages)

    render json: {
      waitingConversations: waiting_conversations.map { |conv| conversation_response(conv) },
      assignedConversations: assigned_conversations.map { |conv| conversation_response(conv) }
    }
  end

  def claim
    return render json: { error: "Conversation is already assigned to an expert" }, status: :unprocessable_entity if @conversation.assigned_expert_id.present?

    @conversation.update!(
      assigned_expert: current_user,
      status: "active"
    )

    @conversation.expert_assignments.create!(
      expert: current_user.expert_profile,
      assigned_at: Time.current,
      status: "active"
    )

    render json: { success: true }
  end

  def unclaim
    return render_forbidden("You are not assigned to this conversation") unless @conversation.assigned_expert_id == current_user.id

    @conversation.update!(
      assigned_expert: nil,
      status: "waiting"
    )

    @conversation.expert_assignments.where(status: "active").update_all(
      status: "unclaimed",
      resolved_at: Time.current
    )

    render json: { success: true }
  end

  def profile
    if current_user.expert_profile
      render json: expert_profile_response(current_user.expert_profile)
    else
      # Create expert profile if it doesn't exist
      expert_profile = current_user.create_expert_profile!
      render json: expert_profile_response(expert_profile)
    end
  end

  def update_profile
    if current_user.expert_profile.update(profile_params)
      render json: expert_profile_response(current_user.expert_profile)
    else
      render json: { errors: current_user.expert_profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def assignment_history
    assignments = current_user.expert_profile.expert_assignments
                              .includes(:conversation)
                              .order(assigned_at: :desc)

    render json: assignments.map { |assignment| assignment_response(assignment) }
  end

  private

  def ensure_expert_profile
    return if current_user.expert_profile

    render json: { error: "Expert profile required" }, status: :forbidden
  end

  def set_conversation
    @conversation = Conversation.find_by(id: params[:conversation_id])
    return if @conversation

    render_not_found("Conversation not found")
  end

  def profile_params
    params.permit(:bio, knowledge_base_links: [])
  end

  def conversation_response(conversation)
    {
      id: conversation.id.to_s,
      title: conversation.title,
      status: conversation.status,
      questionerId: conversation.initiator_id.to_s,
      questionerUsername: conversation.initiator.username,
      assignedExpertId: conversation.assigned_expert_id&.to_s,
      assignedExpertUsername: conversation.assigned_expert&.username,
      createdAt: conversation.created_at.iso8601,
      updatedAt: conversation.updated_at.iso8601,
      lastMessageAt: conversation.last_message_at&.iso8601,
      unreadCount: conversation.unread_count_for_user(current_user)
    }
  end

  def expert_profile_response(profile)
    {
      id: profile.id.to_s,
      userId: profile.user_id.to_s,
      bio: profile.bio,
      knowledgeBaseLinks: profile.knowledge_base_links || [],
      createdAt: profile.created_at.iso8601,
      updatedAt: profile.updated_at.iso8601
    }
  end

  def assignment_response(assignment)
    {
      id: assignment.id.to_s,
      conversationId: assignment.conversation_id.to_s,
      expertId: assignment.expert_id.to_s,
      status: assignment.status,
      assignedAt: assignment.assigned_at.iso8601,
      resolvedAt: assignment.resolved_at&.iso8601,
      rating: assignment.rating
    }
  end
end
