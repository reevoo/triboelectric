require "rack"

module Triboelectric
  class Assets
    def initialize(app, options={})
      @app    = app
      @urls   = options[:urls] || []
      @bucket = options[:bucket]
      @root   = options[:root]
    end

    def call(env)
      path = env[Rack::PATH_INFO]
      response = @app.call(env)
      return response unless active?(path, response)

      if (object = get_object(path))
        response[1][Rack::CONTENT_TYPE]   = object.content_type
        response[1][Rack::CONTENT_LENGTH] = object.content_length
        response[2] = object.body
        return response
      end

      response
    end

    private

    def get_object(path)
      obj_path = path.dup
      obj_path = File.join(@root, obj_path) if @root
      @bucket.object(obj_path).get
    rescue Aws::S3::Errors::NoSuchKey
      nil
    end

    def active?(path, response)
      return unless @bucket
      return unless response.first == 404
      @urls.any? { |url| path.index(url) == 0 }
    end
  end
end
