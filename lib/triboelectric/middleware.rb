require "rack"

module Triboelectric
  class Middleware
    def initialize(app, bucket)
      @app    = app
      @bucket = bucket
    end

    def call(env)
      status, headers, body = @app.call(env)

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
      path.sub(/^\//, "")
      object = @bucket.object(path)
      return unless object.exists?
      object.get
    end
  end
end
