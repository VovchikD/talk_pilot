module Ai
  class ConversationReply
    DEFAULT_MODEL = "gpt-4o-mini"
    MAX_CONTEXT_MESSAGES = 20

    def initialize(conversation_session)
      @conversation_session = conversation_session
    end

    def self.call(conversation_session)
      new(conversation_session).call
    end

    def call
      response = client.chat.completions.create(
        model: model,
        messages: messages_payload,
        temperature: 0.7,
        response_format: {
          type: "json_object"
        }
      )

      parse_response(response)
    rescue JSON::ParserError => error
      raise ::Ai::InvalidResponseError, "OpenAI returned invalid JSON: #{error.message}"
    end

    private

    attr_reader :conversation_session

    def client
      @client ||= OpenAI::Client.new(api_key: api_key)
    end

    def api_key
      Rails.application.credentials.dig(:openai, :secret).presence ||
        raise(::Ai::ConfigurationError, "Set OPENAI_API_KEY or openai.api_key in Rails credentials.")
    end

    def model
      ENV.fetch("OPENAI_MODEL", DEFAULT_MODEL)
    end

    def messages_payload
      [{ role: "system", content: system_prompt }] + conversation_messages
    end

    def system_prompt
      <<~PROMPT
        You are TalkPilot, a friendly and supportive English conversation coach.

        STUDENT PROFILE
        - English level: #{learner_level}
        - Current topic: #{conversation_topic}
        - Native language: Ukrainian

        YOUR GOAL

        Help the learner improve conversational English through natural dialogue.
        Act like a patient native English speaker, not a grammar teacher.

        TEACHING PRINCIPLES

        - Always reply in English.
        - Keep the conversation natural and engaging.
        - Match the learner's English level.
        - Keep replies short (1–3 sentences).
        - Encourage the learner to write complete sentences.
        - Help the learner build confidence.
        - Continue the current topic unless the learner changes it.

        CONVERSATION

        - Always respond to the learner's latest message first.
        - Usually ask one natural follow-up question.
        - Never ask more than one question.
        - Avoid repeating the same questions.
        - Avoid long explanations.

        CORRECTIONS

        - Evaluate only the learner's latest message.
        - Correct at most one important mistake.
        - Correct only mistakes that sound unnatural or could confuse a native speaker.
        - Ignore small punctuation mistakes.
        - Preserve the learner's intended meaning.
        - If the sentence is natural, return no correction.

        The correction should help the learner immediately repeat the correct sentence.

        VOCABULARY

        - Introduce at most one useful word or expression.
        - Only include vocabulary naturally used in your reply.
        - Choose vocabulary appropriate for the learner's level.
        - Do not force vocabulary into every response.

        OUTPUT

        Return ONLY valid JSON.

        {
          "reply": "Natural conversational reply.",
          "corrections": [
            {
              "mistake": "Exact incorrect fragment.",
              "better_sentence": "Full corrected sentence.",
              "explanation": "Short explanation."
            }
          ]
        }

        Rules:

        - corrections must be [] if no correction is needed.
        - vocabulary must be [] if no vocabulary is introduced.
        - Do not include Markdown.
        - Do not include code fences.
        - Do not include any text outside the JSON object.
      PROMPT
    end

    def learner_level
      conversation_session.level.presence ||
        "unknown; infer cautiously from recent messages"
    end

    def conversation_topic
      conversation_session.topic.presence || "general conversation"
    end

    def conversation_messages
      recent_messages.filter_map do |message|
        next unless %w[user assistant].include?(message.role)

        {
          role: message.role,
          content: context_content(message)
        }
      end
    end

    def recent_messages
      conversation_session.messages.chronological.last(MAX_CONTEXT_MESSAGES)
    end

    def context_content(message)
      return message.content.to_s unless message.assistant?

      parsed_assistant_content(message.content.to_s) || message.content.to_s
    end

    def parsed_assistant_content(content)
      parsed = JSON.parse(content)

      parsed["reply"].presence || content
    rescue JSON::ParserError
      nil
    end

    def parse_response(response)
      content = extract_content(response)
      raise ::Ai::InvalidResponseError, "OpenAI returned an empty response." if content.blank?

      Messages::AssistantResponsePresenter.new(JSON.parse(content, symbolize_names: true))
    end

    def extract_content(response)
      if response.respond_to?(:choices)
        response.choices.first&.message&.content.to_s.strip
      else
        response.dig("choices", 0, "message", "content").to_s.strip
      end
    end
  end
end
