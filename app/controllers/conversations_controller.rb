class ConversationsController < ApplicationController
  before_action :authenticate_with_jwt!
  before_action :set_conversation, only: [ :show ]

  def index
    @conversations = current_user.initiated_conversations
                                 .or(current_user.assigned_conversations)
                                 .includes(:initiator, :assigned_expert, :messages)

    render json: @conversations.map { |conv| conversation_response(conv) }
  end

  def show
    return render_forbidden unless can_access_conversation?(@conversation)

    render json: conversation_response(@conversation)
  end

  def create
    @conversation = current_user.initiated_conversations.build(conversation_params)

    if @conversation.save
      render json: conversation_response(@conversation), status: :created
    else
      render json: { errors: @conversation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find_by(id: params[:id])
    return if @conversation

    render_not_found("Conversation not found")
  end

  def can_access_conversation?(conversation)
    conversation.initiator_id == current_user.id ||
      conversation.assigned_expert_id == current_user.id
  end

  def conversation_params
    params.permit(:title)
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
end
