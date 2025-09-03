require "openai"
require "dotenv"
require "amazing_print"

Dotenv.load(File.expand_path("../.env", __dir__))
client = OpenAI::Client.new(api_key: ENV["OPENAI_API_KEY"])

response = client.responses.create(
  model: "gpt-4.1-nano", # or the model that supports code interpreter
  input: [
    { role: "user", content: "Plot y = x^2 for x from -10 to 10." }
    # { role: "user", content: "Generate a CSV file with 3 columns: Name, Age, Country, and 5 rows of sample data. Save it as data.csv and let me download it." }
  ],
  tools: [
    { type: "code_interpreter", container: {type: "auto"} }
  ]
)

# puts response

# annotations = message_outputs.map { |output|
#   output.content.find { |e|
#     e.respond_to?(:annotations) && e.annotations.length.positive?
#   }&.annotations&.find { |a|
#     a.respond_to?(:filename)
#   }
# }.compact

message_outputs = response.output.select do |output|
  output.respond_to?(:type) && output.type == :message
end

outputs_with_annotations = message_outputs.map do |output|
  output.content.find do |message|
    message.respond_to?(:annotations) && message.annotations.length.positive?
  end
end.compact

annotations = outputs_with_annotations.map do |output|
  output.annotations.find do |annotation|
    annotation.respond_to?(:filename)
  end
end.compact

annotations.each do |annotation|
  container_id = annotation.container_id
  file_id = annotation.file_id
  filename = annotation.filename
  file_content = client.containers.files.content.retrieve(file_id, container_id: container_id)

  File.open(filename, "w") do |file|
    file.write(file_content.read)
  end
end

ap annotations
