class ConversationSessionsController < ApplicationController
  before_action :set_conversation_session, only: :show

  def index
    @conversation_sessions = ConversationSession.recent
    @conversation_session = ConversationSession.new
  end

  def show
    @messages = @conversation_session.messages.chronological
    @message = Message.new
  end

  def create
    @conversation_session = ConversationSession.create!(conversation_session_params)

    redirect_to @conversation_session
  end

  private

  def set_conversation_session
    @conversation_session = ConversationSession.find(params[:id])
  end

  def conversation_session_params
    params.require(:conversation_session).permit(:title, :topic, :level)
  end
end
