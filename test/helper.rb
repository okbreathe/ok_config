require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'fileutils'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'ok_config'

class Test::Unit::TestCase

  def new_store(input = nil)
    OkConfig::Store.new(input)
  end
  
end
