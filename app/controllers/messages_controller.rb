class MessagesController < ApplicationController
  before_action :set_conversation_session

  def create
    content = user_message_content
    if content.blank?
      redirect_to @conversation_session, alert: "I could not understand the message. Please try again."
      return
    end

    user_message = @conversation_session.messages.create!(role: "user", content: content)
    user_message.audio.attach(message_params[:audio]) if message_params[:audio].present?

    assistant_reply = Ai::ConversationReply.call(@conversation_session)

    if assistant_reply.present?
      assistant_message = @conversation_session.messages.create!(role: "assistant", content: assistant_reply)
      attach_assistant_audio(assistant_message)
    end

    redirect_to @conversation_session
  rescue Ai::ConfigurationError => error
    redirect_to @conversation_session, alert: error.message
  end

  private

  def set_conversation_session
    @conversation_session = ConversationSession.find(params[:conversation_session_id])
  end

  def message_params
    params.require(:message).permit(:content, :audio)
  end

  def user_message_content
    if message_params[:audio].present?
      Ai::AudioTranscription.call(message_params[:audio])
    else
      message_params[:content].to_s.strip
    end
  end

  def attach_assistant_audio(message)
    speech = Ai::SpeechGeneration.call(message.content)

    message.audio.attach(
      io: speech,
      filename: "assistant-message-#{message.id}.mp3",
      content_type: "audio/mpeg"
    )
  rescue Ai::SpeechGeneration::ConfigurationError
    nil
  rescue StandardError => error
    Rails.logger.warn("Assistant speech generation failed for message #{message.id}: #{error.message}")
  end
end
