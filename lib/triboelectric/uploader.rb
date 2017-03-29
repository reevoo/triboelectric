require "rack/mime"

module Triboelectric
  class Uploader
    def initialize(options = {})
      @bucket = options[:bucket]
      @root   = options[:root]
      @urls   = options[:urls]
    end

    def self.upload(*args)
      new(*args).upload
    end

    def upload
      return unless @bucket
      return if %w(development test).include? ENV["RACK_ENV"]
      files.each do |file|
        @bucket.put_object(
          key: file,
          body: File.open(file, "r"),
          content_type: Rack::Mime.mime_type(File.extname(file), "text/plain"),
        )
      end
    end

    def files
      urls = @urls if @urls.is_a?(Array)
      urls = @urls.values if @urls.is_a?(Hash)

      urls.map do |url|
        if @root
          url = File.join(@root, url)
        else
          url = url.sub(/^\//, "")
        end

        if File.file? url
          url
        else
          Dir[File.join(url, "**/*")].select { |f| File.file? f }
        end
      end.flatten
    end
  end
end
