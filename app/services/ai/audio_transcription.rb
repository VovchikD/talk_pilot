require "pathname"
require "tempfile"

module Ai
  class AudioTranscription
    DEFAULT_MODEL = "gpt-4o-mini-transcribe"

    def initialize(audio)
      @audio = audio
    end

    def self.call(audio)
      new(audio).call
    end

    def call
      raise Ai::TranscriptionError, "Audio recording is missing." if audio.blank?

      response = client.audio.transcriptions.create(
        file: Pathname(audio.tempfile.path),
        model: model,
        language: "en",
        prompt: transcription_prompt
      )

      raise Ai::TranscriptionError, "Audio could not be transcribed. Please try again."  if response.text.blank?
      response.text.to_s.strip
    end

    private

    attr_reader :audio

    def client
      @client ||= OpenAI::Client.new(api_key: api_key)
    end

    def api_key
      Rails.application.credentials.dig(:openai, :secret).presence ||
        raise(Ai::ConfigurationError, "OpenAI API key is not configured.")
    end

    def model
      ENV.fetch("OPENAI_TRANSCRIPTION_MODEL", DEFAULT_MODEL)
    end

    def transcription_prompt
      "Preserve the learner's exact English words and mistakes. Do not correct them."
    end
  end
end
