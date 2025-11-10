class UpdatesController < ApplicationController
  before_action :authenticate_with_jwt!

  def conversations
    user_id = params[:userId]
    since_timestamp = params[:since] ? Time.parse(params[:since]) : 1.hour.ago
    
    return render_forbidden unless user_id.to_i == current_user.id
    
    @conversations = current_user.initiated_conversations
                                .or(current_user.assigned_conversations)
                                .where("updated_at > ?", since_timestamp)
                                .includes(:initiator, :assigned_expert, :messages)
    
    render json: @conversations.map { |conv| conversation_response(conv) }
  end

  def messages
    user_id = params[:userId]
    since_timestamp = params[:since] ? Time.parse(params[:since]) : 1.hour.ago
    
    return render_forbidden unless user_id.to_i == current_user.id
    
    conversation_ids = current_user.initiated_conversations.pluck(:id) + 
                      current_user.assigned_conversations.pluck(:id)
    
    @messages = Message.joins(:conversation)
                      .where(conversation_id: conversation_ids)
                      .where("messages.created_at > ?", since_timestamp)
                      .includes(:sender, :conversation)
                      .order(:created_at)
    
    render json: @messages.map { |msg| message_response(msg) }
  end

  def expert_queue
    expert_id = params[:expertId]
    since_timestamp = params[:since] ? Time.parse(params[:since]) : 1.hour.ago
    
    return render_forbidden unless current_user.expert_profile&.id == expert_id.to_i
    
    waiting_conversations = Conversation.where(status: "waiting")
                                      .where("updated_at > ?", since_timestamp)
                                      .includes(:initiator, :messages)
    
    assigned_conversations = current_user.assigned_conversations
                                       .where(status: "active")
                                       .where("updated_at > ?", since_timestamp)
                                       .includes(:initiator, :messages)
    
    render json: [{
      waitingConversations: waiting_conversations.map { |conv| conversation_response(conv) },
      assignedConversations: assigned_conversations.map { |conv| conversation_response(conv) }
    }]
  end

  private

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
