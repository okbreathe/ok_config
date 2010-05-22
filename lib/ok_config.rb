require 'yaml'
require 'erb'
require 'active_support/core_ext/object/blank'
require File.expand_path('../ok_config/extensions', __FILE__)
require File.expand_path('../ok_config/store', __FILE__)

module OkConfig
  class << self
    attr_accessor :root, :store

    # Paths are to files or directories. If the path is a directory it will
    # load all the files in that directory Omitting any paths will load all
    # files under the root.
    # 
    # ==== Arguments
    # <*String> - One or more file paths. Either absolute path or path relative to OkConfig.root
    #
    # ==== Usage
    # OkConfig.load "foo", "bar"
    def load(*args) 
      @store ||= OkConfig::Store.new
      if args.last.kind_of?(Hash)
        @store.load(args.pop)
      else
        gather_paths(args) { |p| y=YAML.load_file(p); @store.load(y) if y  } 
      end
      @store
    end

    # Same arguments and behavior as #load, however, ensures that
    # subsequently loaded arguments are coerced to their original types
    #
    # This is useful for updating the configuation from params or anything 
    # where the arguments are all strings
    #
    # Supports coercing of arrays, numeric and boolean values
    #
    # Given the existing config
    #
    # { :foo => 1}
    #
    # Loading 
    #
    # { :foo => "2" }
    #
    # Will coerce "2" to an interger
    #
    # NOTE: 
    # If the original value is an array, and the new value is a string it will
    # be treated as a CSV and the string split on commas.
    # Arrays of Boolean values don't work, because that is a silly data
    # structure.
    def safe_load(*args)
      return self.load(args) unless @store # No point in doing a coercive load unless there is a store
      hash =
        if args.last.kind_of?(Hash) 
          args.pop
        else
          h = {}
          gather_paths(args) do |p|
            y = YAML.load_file(p)
            h.merge!(y) if y  
          end
          h
      end
      @store = @store.coercive_deep_merge( hash.recursively{ |h| h.rekey } )
    end

    # Write the current store to disk
    def save(path)
      p = path.slice(0,1) == File::SEPARATOR ? path : File.join(root_path,path)
      path  += ".yml" if !path.index(/\.yml$/)
      store.write(path)
    end

    alias :load_from_params :safe_load

    def [](config)
      @store[config]
    end

    def clear!
      @store = OkConfig::Store.new
    end

    def method_missing(name, *args, &block)
      @store.send(name, *args, &block)
    end

    protected

    def gather_paths(paths)
      paths.each do |path|
        p = path.slice(0,1) == File::SEPARATOR ? path : File.join(root_path,path)
        if File.directory?(p)
          Dir.glob(File.join(p, "*.yml" )).each do |f|
            yield f
          end
        else
          file_exists?(p = File.extname(p) == ".yml" ? p : "#{p}.yml")
          yield p
        end
      end
    end

    def root_path
      raise ArgumentError, "OkConfig.root not set" unless OkConfig.root and File.exists?(OkConfig.root)
      OkConfig.root
    end

    def file_exists?(dir)
      raise IOError, "Path '#{dir}' does not exist!" unless File.exists?(dir)
    end

  end
end # OkConfig

