module Messages
  class AssistantResponsePresenter
    def initialize(payload)
      @payload = payload.to_h.with_indifferent_access
    end

    def to_s
      [reply, correction_note].compact_blank.join("\n\n")
    end

    private

    attr_reader :payload

    def reply
      payload[:reply].to_s.strip.presence
    end

    def correction_note
      correction = Array(payload[:corrections]).first
      return if correction.blank?

      correction = correction.to_h.with_indifferent_access

      [
        "You said: #{correction[:mistake]}",
        "Better: #{correction[:better_sentence]}",
        "Why: #{correction[:explanation]}",
        "Please repeat: #{correction[:better_sentence]}"
      ].compact_blank.join("\n")
    end
  end
end
