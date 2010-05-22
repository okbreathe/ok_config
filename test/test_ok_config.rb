require 'helper'

class TestOkConfig < Test::Unit::TestCase
  context "OkConfig" do

    setup do
      @config = OkConfig
      @config.clear!
      @config.root = File.dirname(File.expand_path(__FILE__)) + '/data/'
    end

    context "normal loading" do

      should "raise an error if the file doesn't exist" do
        assert_raise IOError do
          @config.load "/some/file/that/doesnt/exist"
        end
      end

      should "complain about a missing root if a relative path is specified and the file doesn't exist" do
        OkConfig.clear!
        OkConfig.root = nil
        assert_raise ArgumentError do
          @config.load "foo"
        end
      end

      should "load from a hash" do
        h = { foo: 1, bar: 2, baz: 3 }
        @config.load h
        assert_equal h.symbolize_keys, @config.store
      end

      should "load from a file" do
        @config.load "file"
        assert_equal load_yaml("file"), @config.store
        assert_not_nil @config.store.receipt
      end

      should "load multiple files at once" do
        @config.load "file", "dir/aardvark"
        assert_equal @config.store.name, "aardvark"
        assert_not_nil @config.store.receipt
      end

      should "load from a directory in alphabetical order" do
        @config.load "dir"
        assert @config.store.power_level > 9000
        assert_equal "foo", @config.store.name
      end

      should "allow override configs" do
        @config.load "dir"
        assert @config.store.power_level > 9000
        @config.load "dir/aardvark"
        assert_equal 2, @config.store.power_level
      end

      should "allow specifying absolute paths" do
        tf = "/tmp/ok_config_temp.yml"
        File.open(tf, 'w') {|f| f.write("name: temp") }

        @config.load("/tmp/ok_config_temp.yml")

        assert_equal "temp", @config.store.name

        FileUtils.rm(tf) if File.exists?(tf)
      end
    end # normal loading

    context "safe loading" do

      setup do
        @config.load "safe/base"
      end

      should "work with a hash" do
        @config.safe_load({
            numeric_list: "4,5,6",
            string: 100,
            number: "100",
            string_hash: {foo: 1, bar: 2}
        })
        assert_equal "100", @config.store.string 
        assert_equal 100, @config.store.number
        assert_equal [4,5,6], @config.store.numeric_list
        assert_equal({foo: "1", bar: "2"}, @config.store.string_hash)
      end

      should "work with one or more files" do
        @config.safe_load("safe/overwriter")
        assert_equal "100", @config.store.string 
        assert_equal 100, @config.store.number
        assert_equal [4,5,6], @config.store.numeric_list
        assert_equal({foo: "1", bar: "2"}, @config.store.string_hash)
      end

      should "act like a normal load if the store doesn't exist" do

      end

    end # coercive loading

    context "saving" do
      setup do
        @temp_path = File.dirname(File.expand_path(__FILE__)) + '/tmp/'
        FileUtils.mkdir_p(@temp_path) unless File.exists?(@temp_path)
      end

      should "be able to write the configuration file to disk" do
        save_path = File.join(@temp_path, "save")
        h         = { foo: 1, bar: 2, baz: 3 }
        @config.load(h)
        @config.save(save_path)
        assert File.exists?(save_path+".yml")
        assert_equal h, YAML.load_file(save_path+".yml")
      end

      teardown do
        FileUtils.rm_rf(@temp_path) if File.exists?(@temp_path)
      end

    end
      

  end

  def load_yaml(p)
    p = p.slice(0,1) == "/" ? p : @config.root + p
    p = File.extname(p) == ".yml" ? p : "#{p}.yml"
    YAML.load_file(p).symbolize_keys
  end
end
