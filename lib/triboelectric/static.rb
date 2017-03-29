require "rack"

module Triboelectric
  class Static
    def initialize(app, options = {})
      Uploader.upload(options) if options.fetch(:upload, true)
      @app    = app
      @static = Rack::Static.new(@app, options)
      @bucket = options[:bucket]
      @root   = options[:root]
    end

    def call(env)
      return @app.call(env) unless @static.can_serve(env[Rack::PATH_INFO])

      status, headers, body = @static.call(env)

      if (object = get_object(env, status))
        headers[Rack::CONTENT_TYPE]   = object.content_type
        headers[Rack::CONTENT_LENGTH] = object.content_length
        status = 200
        body   = object.body
      end

      [status, headers, body]
    end

    private

    def get_object(env, status)
      return unless @bucket
      return unless status == 404
      path = env[Rack::PATH_INFO]
      if @root
        path = File.join(@root, path)
      else
        path = path.sub(/^\//, "")
      end
      object = @bucket.object(path)
      return unless object.exists?
      object.get
    end
  end
end
