require "spec_helper"

RSpec.describe Triboelectric::Uploader do
  subject { described_class.new(options) }

  describe "#files" do
    context "with routes" do
      let(:options) do
        {
          urls: {
            "/" => "spec/fixture/index.html",
            "/assets" => "spec/fixture/assets",
          },
        }
      end

      specify do
        expect(subject.files).to contain_exactly(
          "spec/fixture/index.html",
          "spec/fixture/assets/foo.css",
        )
      end
    end

    context "with routes and a root" do
      let(:options) do
        {
          urls: {
            "/" => "index.html",
            "/assets" => "/assets",
          },
          root: "spec/fixture",
        }
      end

      specify do
        expect(subject.files).to contain_exactly(
          "spec/fixture/index.html",
          "spec/fixture/assets/foo.css",
        )
      end
    end

    context "with a list" do
      let(:options) do
        {
          urls: %w(/spec/fixture),
        }
      end

      specify do
        expect(subject.files).to contain_exactly(
          "spec/fixture/assets/foo.css",
          "spec/fixture/baz.html",
          "spec/fixture/index.html",
        )
      end
    end

    context "with a list and a root" do
      let(:options) do
        {
          urls: %w(/assets),
          root: "spec/fixture",
        }
      end

      specify do
        expect(subject.files).to contain_exactly("spec/fixture/assets/foo.css")
      end
    end
  end

  describe "#upload" do
    let(:options) do
      {
        urls: %w(/assets),
        root: "spec/fixture",
        bucket: bucket,
      }
    end

    let(:bucket) { double(:bucket) }

    it "uploads the file to the bucket" do
      allow(bucket).to receive(:object)
        .and_return(double(:object, exists?: false))

      expect(bucket).to receive(:put_object) do |args|
        expect(args[:key]).to eq "spec/fixture/assets/foo.css"
        expect(args[:body].read).to eq "h1 { color: red }\n"
        expect(args[:content_type]).to eq "text/css"
      end.once
      subject.upload
    end

    context "with no bucket configured" do
      let(:options) do
        {
          urls: %w(/assets),
          root: "spec/fixture",
        }
      end

      it "does nothing" do
        subject.upload
      end
    end

    context "if files allready exist" do
      let(:options) do
        {
          urls: {
            "/" => "spec/fixture/index.html",
            "/assets" => "spec/fixture/assets",
          },
          bucket: bucket,
        }
      end

      it "only uploads the file that is not found on the bucket" do
        allow(bucket).to receive(:object)
          .with("spec/fixture/index.html")
          .and_return(double(:object, exists?: true))

        allow(bucket).to receive(:object)
          .with("spec/fixture/assets/foo.css")
          .and_return(double(:object, exists?: false))

        expect(bucket).to receive(:put_object) do |args|
          expect(args[:key]).to eq "spec/fixture/assets/foo.css"
          expect(args[:body].read).to eq "h1 { color: red }\n"
          expect(args[:content_type]).to eq "text/css"
        end.once

        subject.upload
      end
    end

    %w(development test).each do |environment|
      context "when RACK_ENV is #{environment}" do
        let(:options) do
          {
            urls: %w(/assets),
            root: "spec/fixture",
            bucket: bucket,
          }
        end

        let(:bucket) { double(:bucket) }

        it "does nothing" do
          with_env("RACK_ENV" => environment) do
            subject.upload
          end
        end
      end
    end
  end
end
