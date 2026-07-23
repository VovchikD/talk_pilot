module Ai
  class SpeechGeneration
    class ConfigurationError < StandardError; end

    DEFAULT_MODEL = "gpt-4o-mini-tts"
    DEFAULT_VOICE = "alloy"

    def initialize(text)
      @text = text
    end

    def self.call(text)
      new(text).call
    end

    def call
      audio = client.audio.speech.create(
        model: model,
        voice: voice,
        input: text,
        response_format: :mp3,
        instructions: "Speak clearly, naturally, and at a comfortable pace for an English learner."
      )

      audio.rewind
      audio
    end

    private

    attr_reader :text

    def client
      @client ||= OpenAI::Client.new(api_key: api_key)
    end

    def api_key
      Rails.application.credentials.dig(:openai, :secret).presence ||
        raise(::Ai::ConfigurationError, "Set OPENAI_ACCESS_TOKEN or OPENAI_API_KEY to generate speech.")
    end

    def model
      ENV.fetch("OPENAI_TTS_MODEL", DEFAULT_MODEL)
    end

    def voice
      ENV.fetch("OPENAI_TTS_VOICE", DEFAULT_VOICE)
    end
  end
end
