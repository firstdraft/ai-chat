module AI
  class Response
    attr_reader :id, :model, :usage, :total_tokens

    def initialize(response)
      @id = response.id
      @model = response.model
      @usage = response.usage.to_h.slice(:input_tokens, :output_tokens, :total_tokens)
      @total_tokens = @usage[:total_tokens]
    end
  end
end