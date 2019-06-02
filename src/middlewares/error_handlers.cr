macro initialize_error_handlers
  {% for code in HTTP::Status.constants %}
  Kemal.config.add_error_handler HTTP::Status::{{code.id}}.value do |context, exception|
    JSON.build context.response, indent: 2 do |builder|
      builder.object do
        builder.field "errors" do
          builder.array do
            builder.string HTTP::Status::{{code.id}}.description || "{{code.id}}".capitalize.gsub('_', ' ')
          end
        end
      end
    end
    nil
  end
  {% end %}
end
