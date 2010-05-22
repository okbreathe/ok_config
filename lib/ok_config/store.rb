module OkConfig

    module HashWithMethodSyntax

      def method_missing(name, *args, &block)
        name = name.to_sym
        if key?(name) and value = self[name]
          add_method_syntax(name)
          value.extend(HashWithMethodSyntax) if value.is_a?(Hash)
          value
        else
          nil
        end
      end

      private

      def add_method_syntax(name)
        metaclass.send(:define_method, name) { self[name] }
      end

    end # HashWithMethodSyntax

    class Store < Hash

      include HashWithMethodSyntax

      def initialize(path_or_hash = nil)
        self.update(path_or_hash ? create_store(path_or_hash) : {})
        self
      end

      # Load a new set of configurations into the existing configuration
      def load(path_or_hash)
        self.update deep_merge(create_store(path_or_hash))
      end

      def write(path, opts = {})
        dir = File.dirname(path)
        raise ArgumentError, "File path, '#{path}' does not exist! OkConfig.root is '#{OkConfig.root}'" unless File.exists?(dir) 
        raise ArgumentError, "File path, '#{dir}' is a file! OkConfig.root is '#{OkConfig.root}'" if File.exists?(dir) and !File.directory?(dir)
        File.open(path, 'w') {|f| f.puts OkConfig.store.to_yaml }
        true
      end

      def ==(other)
        super(other.kind_of?(Hash) ? other.symbolize_keys : other)
      end

      # Only deal with symbols
      def [](k)
        super(k.to_sym)
      end

      def []=(k,v)
        super(k.to_sym,v)
      end

      protected

      def create_store(input)
        hash = 
          if input.kind_of?(String) 
            raise IOError, "File '#{input}' does not exist. " unless File.exists? input
            YAML.load(ERB.new(File.read(input)).result).to_hash
          else
            input.kind_of?(Hash) ? input.to_hash : nil
          end
        hash ? hash.recursively{|h| h.rekey } : raise(ArgumentError, "'#{input}' is not a hash, or a string representing the path to a yaml file.")
      rescue Errno::ENOENT => e
        warn e.message
      end

    end # Store
end # OkConfig
