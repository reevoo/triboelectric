require "spec_helper"
require "rack/lint"
require "rack/mock"

RSpec.describe Triboelectric::Static do
  subject { setup_app(options) }
  let(:request) { Rack::MockRequest.new(subject) }

  describe "with no config" do
    let(:options) { {} }

    it "passes everything through" do
      res = request.get("/")
      expect(res).to be_ok
      expect(res.content_type).to eq "text/plain"
      expect(res.body).to eq "Hello From The App"
    end
  end

  describe "serving local static assets" do
    let(:options) do
      {
        urls: %w(/assets),
        root: "spec/fixture",
      }
    end

    it "serves the assets" do
      res = request.get("/assets/foo.css")
      expect(res).to be_ok
      expect(res.content_type).to eq "text/css"
      expect(res.body).to eq "h1 { color: red }\n"
    end

    it "returns a 404 for an asset not present localy" do
      res = request.get("/assets/bar.css")
      expect(res.status).to eq 404
      expect(res.content_type).to eq "text/plain"
      expect(res.body).to eq "File not found: /assets/bar.css\n"
    end
  end

  describe "when configured with a S3 bucket" do
    let(:options) do
      {
        urls: %w(/assets),
        root: "spec/fixture",
        bucket: DummyBucket.new(
          "spec/fixture/assets/foo.css" => double(
            :s3_object,
            exists?: true,
            get: foo,
          ),
          "spec/fixture/assets/bar.css" => double(
            :s3_object,
            exists?: true,
            get: bar,
          ),
          "spec/fixture/assets/baz.css" => double(
            :s3_object,
            exists?: false,
          ),
        ),
      }
    end

    let(:foo) do
      double(
        :bar_s3_object,
        content_type: "text/css",
        content_length: "24",
        body: ["we should never see this"],
      )
    end

    let(:bar) do
      double(
        :bar_s3_object,
        content_type: "text/css",
        content_length: "20",
        body: ["h2 { color: green }\n"],
      )
    end

    it "serves local assets" do
      res = request.get("/assets/foo.css")
      expect(res).to be_ok
      expect(res.content_type).to eq "text/css"
      expect(res.body).to eq "h1 { color: red }\n"
    end

    it "serves assets not present localy from the bucket" do
      res = request.get("/assets/bar.css")
      expect(res).to be_ok
      expect(res.content_type).to eq "text/css"
      expect(res.body).to eq "h2 { color: green }\n"
    end

    it "returns a 404 for assets not present localy or in the bucket" do
      res = request.get("/assets/baz.css")
      expect(res.status).to eq 404
      expect(res.content_type).to eq "text/plain"
      expect(res.body).to eq "File not found: /assets/baz.css\n"
    end
  end

  describe "when configured with an index" do
    describe "found localy" do
      let(:options) do
        {
          urls: [""],
          root: "spec/fixture",
          index: "index.html",
        }
      end

      it "serves the local index" do
        res = request.get("/")
        expect(res).to be_ok
        expect(res.content_type).to eq "text/html"
        expect(res.body).to eq "<h1>Index</h1>\n"
      end
    end

    describe "from s3" do
      let(:options) do
        {
          urls: %w(/spec/fixture/assets),
          bucket: DummyBucket.new(
            "spec/fixture/assets/index.html" => double(
              :s3_object,
              exists?: true,
              get: index,
            ),
          ),
          index: "index.html",
          upload: false,
        }
      end

      let(:index) do
        double(
          :bar_s3_object,
          content_type: "text/html",
          content_length: "18",
          body: ["<h1>S3 Index</h1>\n"],
        )
      end

      it "serves the index from s3" do
        res = request.get("/spec/fixture/assets/")
        expect(res).to be_ok
        expect(res.content_type).to eq "text/html"
        expect(res.body).to eq "<h1>S3 Index</h1>\n"
      end
    end
  end

  describe "when configured with routes" do
    let(:options) do
      {
        urls: {
          "/bar/" => "bar.html",
          "/baz/" => "baz.html",
        },
        root: "spec/fixture",
        bucket: DummyBucket.new(
          "spec/fixture/bar.html" => double(
            :s3_object,
            exists?: true,
            get: bar,
          ),
        ),
        upload: false,
      }
    end

    let(:bar) do
      double(
        :bar_s3_object,
        content_type: "text/html",
        content_length: "13",
        body: ["<h2>Bar</h2>\n"],
      )
    end


    it "serves a routed file from s3" do
      res = request.get("/bar/")
      expect(res).to be_ok
      expect(res.body).to eq "<h2>Bar</h2>\n"
      expect(res.content_type).to eq "text/html"
    end

    it "serves a routed file from local" do
      res = request.get("/baz/")
      expect(res).to be_ok
      expect(res.body).to eq "<h2>Baz</h2>\n"
      expect(res.content_type).to eq "text/html"
    end
  end

  describe "when configured with header rules" do
    let(:options) do
      {
        urls: %w(/assets),
        root: "spec/fixture",
        bucket: DummyBucket.new(
          "spec/fixture/assets/bar.css" => double(
            :s3_object,
            exists?: true,
            get: bar,
          ),
        ),
        header_rules: [
          [:all, { "Cache-Control" => "max-age=31536000, public" }],
        ],
        upload: false,
      }
    end

    let(:bar) do
      double(
        :bar_s3_object,
        content_type: "text/css",
        content_length: "19",
        body: ["h2 { color: green }"],
      )
    end

    it "applies the rule to a local file" do
      res = request.get("/assets/foo.css")
      expect(res).to be_ok
      expect(res.headers["Cache-Control"]).to eq "max-age=31536000, public"
    end

    it "applies the rule to a remote file" do
      res = request.get("/assets/bar.css")
      expect(res).to be_ok
      expect(res.headers["Cache-Control"]).to eq "max-age=31536000, public"
    end
  end

  describe "uploading" do
    let(:options) do
      {
        urls: %w(/assets),
        root: "spec/fixture",
        bucket: bucket,
      }
    end
    let(:bucket) { double(:bucket) }

    it "uploads the files on startup" do
      expect(Triboelectric::Uploader).to receive(:upload).with(options)
      setup_app(options)
    end
  end

  class DummyApp
    def call(_env)
      [200, { "Content-Type" => "text/plain" }, ["Hello From The App"]]
    end
  end

  def setup_app(*args)
    Rack::Lint.new(described_class.new(DummyApp.new, *args))
  end

  class DummyBucket
    def initialize(mocks = {})
      @mocks = mocks
    end

    def object(path)
      @mocks[path]
    end

    def put_object(*_args)
    end
  end
end
