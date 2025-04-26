# frozen_string_literal: true

module AI
  class Chat
    # ActionText support for AI::Chat
    module ActionTextSupport
      # Extracts content from an ActionText object, preserving text and images
      # @param rich_text [ActionText::RichText] the rich text object to process
      # @return [Array<Hash>] array of content parts in AI::Chat compatible format
      def extract_actiontext_content(rich_text)
        # Skip if ActionText is not defined in the current environment
        return [{text: rich_text.to_s}] unless defined?(ActionText::RichText)
        
        # Get the HTML content
        html_content = rich_text.to_s
        
        # Parse the HTML to extract text and image references
        content_parts = []
        
        # Try to use Nokogiri if available for robust HTML parsing
        if defined?(Nokogiri)
          doc = Nokogiri::HTML::DocumentFragment.parse(html_content)
          process_with_nokogiri(doc, content_parts)
        else
          # Fallback to simpler regexp-based parsing
          process_with_regexp(html_content, content_parts)
        end
        
        # Return original text if no parts were extracted
        content_parts.empty? ? [{text: html_content}] : content_parts
      end
      
      private
      
      # Process HTML content using Nokogiri
      # @param doc [Nokogiri::HTML::DocumentFragment] the parsed HTML document
      # @param content_parts [Array<Hash>] the array to add content parts to
      def process_with_nokogiri(doc, content_parts)
        # Current text buffer
        text_buffer = ""
        
        doc.children.each do |node|
          if node.name == "action-text-attachment"
            # Flush text buffer before processing attachment
            unless text_buffer.empty?
              content_parts << {text: text_buffer.strip}
              text_buffer = ""
            end
            
            # Extract image from Rails attachment
            sgid = node["sgid"]
            if sgid && defined?(GlobalID::Locator)
              begin
                attachment = GlobalID::Locator.locate_signed(sgid)
                if attachment && attachment.respond_to?(:blob)
                  if defined?(Rails) && Rails.application.respond_to?(:routes)
                    image_url = Rails.application.routes.url_helpers.rails_blob_path(attachment.blob, only_path: true)
                    content_parts << {image: image_url}
                  else
                    # Fallback to direct URL if available
                    content_parts << {image: attachment.blob.url} if attachment.blob.respond_to?(:url)
                  end
                end
              rescue => e
                # Silently continue if attachment can't be loaded
              end
            end
          elsif node.name == "figure" && node.at_css("img")
            # Flush text buffer before processing figure
            unless text_buffer.empty?
              content_parts << {text: text_buffer.strip}
              text_buffer = ""
            end
            
            # Extract image from figure tag
            img = node.at_css("img")
            src = img["src"]
            content_parts << {image: src} if src
          else
            # Extract text, preserving basic formatting
            text_buffer += node.text
          end
        end
        
        # Add any remaining text
        content_parts << {text: text_buffer.strip} unless text_buffer.empty?
      end
      
      # Process HTML content using regular expressions
      # @param html_content [String] the HTML content to process
      # @param content_parts [Array<Hash>] the array to add content parts to
      def process_with_regexp(html_content, content_parts)
        # Split by attachment tags or figure tags
        parts = html_content.split(/(<action-text-attachment[^>]+>|<figure>.*?<\/figure>)/)
        
        parts.each do |part|
          if part.start_with?("<action-text-attachment")
            # Extract image SGID from attachment
            sgid_match = part.match(/sgid="([^"]+)"/)
            
            if sgid_match && defined?(GlobalID::Locator)
              begin
                sgid = sgid_match[1]
                attachment = GlobalID::Locator.locate_signed(sgid)
                if attachment && attachment.respond_to?(:blob)
                  if defined?(Rails) && Rails.application.respond_to?(:routes)
                    image_url = Rails.application.routes.url_helpers.rails_blob_path(attachment.blob, only_path: true)
                    content_parts << {image: image_url}
                  else
                    # Fallback to direct URL if available
                    content_parts << {image: attachment.blob.url} if attachment.blob.respond_to?(:url)
                  end
                end
              rescue => e
                # Silently continue if attachment can't be loaded
              end
            end
          elsif part.start_with?("<figure")
            # Extract image from figure tag
            img_match = part.match(/src="([^"]+)"/)
            content_parts << {image: img_match[1]} if img_match
          elsif !part.strip.empty?
            # Clean up text by removing HTML tags
            if defined?(ActionController::Base)
              clean_text = ActionController::Base.helpers.strip_tags(part).strip
            else
              # Simple HTML tag removal
              clean_text = part.gsub(/<[^>]+>/, "").strip
            end
            
            content_parts << {text: clean_text} unless clean_text.empty?
          end
        end
      end
    end
  end
end