require "./spec_helper"

describe Docopt do
  describe ".docopt_config" do
    it "parses command line arguments with docopt" do
      doc = "Usage: test [--verbose=<level>]"
      argv = ["--verbose", "2"]

      options = Docopt.docopt_config(doc, argv: argv)

      options["--verbose"].should eq("2")
    end

    it "reads from environment variables when CLI not provided" do
      doc = "Usage: test [--verbose=<level>]"
      ENV["TEST_VERBOSE"] = "5"

      begin
        options = Docopt.docopt_config(doc, env_prefix: "TEST")
        options["--verbose"].should eq("5")
      ensure
        ENV.delete("TEST_VERBOSE")
      end
    end

    it "prioritizes CLI arguments over environment variables" do
      doc = "Usage: test [--verbose=<level>]"
      argv = ["--verbose", "cli"]
      ENV["TEST_VERBOSE"] = "env"

      begin
        options = Docopt.docopt_config(doc, argv: argv, env_prefix: "TEST")
        options["--verbose"].should eq("cli")
      ensure
        ENV.delete("TEST_VERBOSE")
      end
    end

    it "handles missing values gracefully" do
      doc = "Usage: test [--verbose=<level>]"
      argv = [] of String

      options = Docopt.docopt_config(doc, argv: argv)

      options["--verbose"].should be_nil
    end

    it "supports multiple options" do
      doc = "Usage: test [--verbose=<level>] [--output=<file>]"
      argv = ["--verbose", "2"]
      ENV["TEST_OUTPUT"] = "result.txt"

      begin
        options = Docopt.docopt_config(doc, argv: argv, env_prefix: "TEST")
        options["--verbose"].should eq("2")
        options["--output"].should eq("result.txt")
      ensure
        ENV.delete("TEST_OUTPUT")
      end
    end

    it "converts environment variable names correctly" do
      doc = "Usage: test [--input-file=<path>]"
      ENV["MYAPP_INPUT_FILE"] = "/path/to/file"

      begin
        options = Docopt.docopt_config(doc, env_prefix: "MYAPP")
        options["--input-file"].should eq("/path/to/file")
      ensure
        ENV.delete("MYAPP_INPUT_FILE")
      end
    end

    it "handles basic config file" do
      doc = "Usage: test [--verbose=<level>]"
      temp_config = "/tmp/test_config.yml"
      File.write(temp_config, {"--verbose" => "1"}.to_yaml)

      begin
        options = Docopt.docopt_config(doc, config_file_path: temp_config)
        options["--verbose"].should eq("1")
      ensure
        File.delete(temp_config) if File.exists?(temp_config)
      end
    end
  end
end
