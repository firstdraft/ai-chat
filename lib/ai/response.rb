module AI
  class Response
    attr_reader :id, :model, :usage, :total_tokens

    def initialize(response)
      @id = response.id
      @model = response.model
      @usage = response.usage.to_h.slice(:input_tokens, :output_tokens, :total_tokens)
      @total_tokens = @usage[:total_tokens]
    end

    def to_hash
      hash = { "#{self.class.name}" => {} }
      
      instance_variables.sort.each do |var|
        value = instance_variable_get(var)
        hash["#{self.class.name}"][var.to_s] = value unless value.nil?
      end
      
      hash
    end
  end
end