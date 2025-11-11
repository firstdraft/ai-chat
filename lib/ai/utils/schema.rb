module AI::Utils
  module Schema
    attr_accessor :schema_description

    def schema
      return @schema_as_hash if @schema_as_hash.empty?
      JSON.pretty_generate(@schema_as_hash)
    end

    def generate_schema!
      return unless schema_description
      system_prompt = <<~PROMPT
        You are an expert at creating JSON Schemas for OpenAI's Structured Outputs feature.

        Generate a valid JSON Schema that follows these strict rules:

        ## OUTPUT FORMAT
        Return a JSON object with this root structure:
        - "name": a short snake_case identifier for the schema
        - "strict": must be true
        - "schema": the actual JSON Schema object

        ## SCHEMA REQUIREMENTS

        ### Critical Rules:
        1. Root schema must be "type": "object" (not anyOf)
        2. Set "additionalProperties": false on ALL objects (including nested ones)
        3. ALL properties must be in "required" arrays (no optional fields unless using union types)
        4. Always specify "items" for arrays

        ### Supported Types:
        - string, number, boolean, integer, object, array, enum, anyOf

        ### Optional Fields:
        To make a field optional, use union types:
        - "type": ["string", "null"] for optional string
        - "type": ["number", "null"] for optional number
        - etc.

        ### String Properties (use when appropriate):
        - "pattern": regex pattern (e.g., "^@[a-zA-Z0-9_]+$" for usernames)
        - "format": predefined formats (date-time, time, date, duration, email, hostname, ipv4, ipv6, uuid)
        - Example: {"type": "string", "format": "email", "description": "User's email address"}

        ### Number Properties (use when appropriate):
        - "minimum": minimum value (inclusive)
        - "maximum": maximum value (inclusive)
        - "exclusiveMinimum": minimum value (exclusive)
        - "exclusiveMaximum": maximum value (exclusive)
        - "multipleOf": must be multiple of this value
        - Example: {"type": "number", "minimum": -130, "maximum": 130, "description": "Temperature in degrees"}

        ### Array Properties (use when appropriate):
        - "minItems": minimum number of items
        - "maxItems": maximum number of items
        - Example: {"type": "array", "items": {...}, "minItems": 1, "maxItems": 10}

        ### Enum Values:
        Use enums for fixed sets of values:
        - Example: {"type": "string", "enum": ["draft", "published", "archived"]}

        ### Nested Objects:
        All nested objects MUST have:
        - "additionalProperties": false
        - Complete "required" arrays
        - Clear "description" fields

        ### Recursive Schemas:
        Support recursion using "$ref":
        - Root recursion: {"$ref": "#"}
        - Definition reference: {"$ref": "#/$defs/node_name"}

        ### Descriptions:
        Add clear, helpful "description" fields for all properties to guide the model.

        ## CONSTRAINTS
        - Max 5000 properties total, 10 levels of nesting
        - Max 1000 enum values across all enums
        - Total string length of all names/values cannot exceed 120,000 chars

        ## EXAMPLE OUTPUTS

        Simple example:
        {
          "name": "user_profile",
          "strict": true,
          "schema": {
            "type": "object",
            "properties": {
              "name": {"type": "string", "description": "User's full name"},
              "age": {"type": "integer", "minimum": 0, "maximum": 150, "description": "User's age in years"},
              "email": {"type": "string", "format": "email", "description": "User's email address"}
            },
            "required": ["name", "age", "email"],
            "additionalProperties": false
          }
        }

        Complex example with arrays and nesting:
        {
          "name": "recipe_collection",
          "strict": true,
          "schema": {
            "type": "object",
            "properties": {
              "recipes": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "name": {"type": "string", "description": "Recipe name"},
                    "ingredients": {
                      "type": "array",
                      "items": {
                        "type": "object",
                        "properties": {
                          "name": {"type": "string"},
                          "quantity": {"type": "string"}
                        },
                        "required": ["name", "quantity"],
                        "additionalProperties": false
                      }
                    }
                  },
                  "required": ["name", "ingredients"],
                  "additionalProperties": false
                }
              }
            },
            "required": ["recipes"],
            "additionalProperties": false
          }
        }

        Return ONLY the JSON object, no additional text or explanation.
      PROMPT

      response = client.responses.create(
        model: "o4-mini",
        input: [
          {role: :system, content: system_prompt},
          {role: :user, content: schema_description}
        ],
        text: {format: {type: "json_object"}},
        reasoning: {effort: "high"}
      )

      output_text = response.output_text

      if !output_text.nil? && !output_text.empty?
        generated = JSON.parse(output_text)
        self.schema = {
          "name" => generated["name"],
          "strict" => generated["strict"],
          "schema" => generated["schema"]
        }
      else
        STDERR.puts "Failed to generate schema from OpenAI"
      end
    end
  end
end
