require File.expand_path('../../helper', __FILE__)

class TestOkConfig < Test::Unit::TestCase

  context "An instance of OkConfig::Store" do

    setup do
      @yaml = File.expand_path('../../data/simple.yml', __FILE__)
      @hash = {
        'a' => 'a1',
        'b' => {
          'b1' => 'b11',
          'b2' => 'b21'
        },
        'c' => {
          'c1' => {
            'd1' => 'd11',
            'd2' => 'd21',
          },
          'c2' => 'c21'
        }
      } 
      @hash2 = {
        'a' => 'CHANGED',
        'b' => {
          'b1' => 'CHANGED',
          'b3' => 'ADDED'
        },
        'c' => {
          'c1' => {
            'd2' => 'CHANGED'
          }
        }
      } 
    end

    should "return an empty has without arguments" do
      assert_equal({}, new_store)
    end

    should "create a store from a YAML file" do
      assert_equal YAML.load_file(@yaml).symbolize_keys, new_store(@yaml)
    end

    should "be able create a store from a hash" do
      assert_equal @hash.symbolize_keys, new_store(@hash)
    end

    should "be able to merge changes from a hash" do
      store = new_store(@hash)
      store.load(@hash2)
      assert_equal @hash.deep_merge(@hash2).symbolize_keys, store
    end

    should "be able to load changes into itself from a yaml file" do
      store = new_store(@hash).load(@yaml) 
      yaml  = @hash.deep_merge(YAML.load_file(@yaml)).symbolize_keys
      assert_equal yaml, store
    end

    should "raise an error if the path to the yaml file does not exist" do
      assert_raise IOError do
        new_store("some/file/that/doesnt/exist")
      end
    end

    should "allow you to use method syntax" do
      store = new_store(@hash)
      assert_equal 'b11', store.b.b1
      assert_equal 'd11', store.c.c1.d1
    end

    should "return nil if the requested key does not exist" do
      store = new_store(@hash)
      assert_nil store.foo
    end

    should "not allow you to overwrite hash methods" do
      store = new_store
      store["is_a?"] = 'foo'
      store["class"] = 'foo'
      assert_equal OkConfig::Store, store.class
    end

  end
end
