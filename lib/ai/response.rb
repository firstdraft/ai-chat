module AI
  class Response
    attr_reader :id, :model, :usage, :total_tokens

    def initialize(response)
      @id = response.id
      @model = response.model
      @usage = response.usage.to_h.slice(:input_tokens, :output_tokens, :total_tokens)
      @total_tokens = @usage[:total_tokens]
    end

    # Support for Ruby's pp (pretty print)
    def pretty_print(q)
      q.group(1, "#<#{self.class}", '>') do
        instance_variables.sort.each_with_index do |var, i|
          q.breakable
          q.text "#{var}="
          q.pp instance_variable_get(var)
          q.text "," if i < instance_variables.length - 1
        end
      end
    end
  end
end
