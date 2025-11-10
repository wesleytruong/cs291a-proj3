class MessagesController < ApplicationController
  before_action :authenticate_with_jwt!
  before_action :set_conversation, only: [ :index ]
  before_action :set_message, only: [ :mark_read ]

  def index
    return render_forbidden unless can_access_conversation?(@conversation)

    @messages = @conversation.messages.includes(:sender).order(:created_at)
    render json: @messages.map { |msg| message_response(msg) }
  end

  def create
    @conversation = Conversation.find_by(id: params[:conversationId])
    unless @conversation
      render_not_found("Conversation not found")
      return
    end

    unless can_access_conversation?(@conversation)
      render_forbidden
      return
    end

    @message = @conversation.messages.build(message_params)
    @message.sender = current_user
    @message.sender_role = determine_sender_role(@conversation, current_user)

    if @message.save
      render json: message_response(@message), status: :created
    else
      render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def mark_read
    if @message.sender_id == current_user.id
      render_forbidden("Cannot mark your own messages as read")
      return
    end

    @message.update!(is_read: true)
    render json: { success: true }
  end

  private

  def set_conversation
    @conversation = Conversation.find_by(id: params[:conversation_id])
    return if @conversation

    render_not_found("Conversation not found")
  end

  def set_message
    @message = Message.find_by(id: params[:id])
    return if @message

    render_not_found("Message not found")
  end

  def can_access_conversation?(conversation)
    conversation.initiator_id == current_user.id ||
      conversation.assigned_expert_id == current_user.id
  end

  def determine_sender_role(conversation, user)
    if user.id == conversation.initiator_id
      "initiator"
    elsif user.id == conversation.assigned_expert_id
      "expert"
    else
      "initiator" # default fallback
    end
  end

  def message_params
    params.permit(:content)
  end

  def message_response(message)
    {
      id: message.id.to_s,
      conversationId: message.conversation_id.to_s,
      senderId: message.sender_id.to_s,
      senderUsername: message.sender.username,
      senderRole: message.sender_role,
      content: message.content,
      timestamp: message.created_at.iso8601,
      isRead: message.is_read
    }
  end
end
