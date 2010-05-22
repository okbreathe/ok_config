class Object
	def metaclass
		class << self
			self
		end
	end
end

class Hash
  # From Facets 2.8.1
  # Rekey a hash.
  #
  #   rekey()
  #   rekey(to_key, from_key)
  #   rekey{ |key| ... }
  #
  # If no arguments or block are given, then all keys are converted
  # to Symbols.
  #
  # If two keys are given, then the second key is changed to
  # the first. You can think of it as +alias+ for hash keys.
  #
  #   foo = { :a=>1, :b=>2 }
  #   foo.rekey('a',:a)       #=> { 'a'=>1, :b=>2 }
  #   foo.rekey('b',:b)       #=> { 'a'=>1, 'b'=>2 }
  #   foo.rekey('foo','bar')  #=> { 'a'=>1, 'b'=>2 }
  #
  # If a block is given, converts all keys in the Hash accroding
  # to the given block. If the block returns +nil+ for given key,
  # then that key will be left intact.
  #
  #   foo = { :name=>'Gavin', :wife=>:Lisa }
  #   foo.rekey{ |k| k.to_s }  #=>  { "name"=>"Gavin", "wife"=>:Lisa }
  #   foo.inspect              #=>  { :name =>"Gavin", :wife=>:Lisa }
  #
  # CREDIT: Trans, Gavin Kistner

  def rekey(*args, &block)
    dup.rekey!(*args, &block)
  end

  # Synonym for Hash#rekey, but modifies the receiver in place (and returns it).
  #
  #   foo = { :name=>'Gavin', :wife=>:Lisa }
  #   foo.rekey!{ |k| k.to_s }  #=>  { "name"=>"Gavin", "wife"=>:Lisa }
  #   foo.inspect               #=>  { "name"=>"Gavin", "wife"=>:Lisa }
  #
  # CREDIT: Trans, Gavin Kistner

  def rekey!(*args, &block)
    # for backward comptability (TODO: DEPRECATE).
    block = args.pop.to_sym.to_proc if args.size == 1
    # if no args use block.
    if args.empty?
      block = lambda{|k| k.to_sym} unless block
      keys.each do |k|
        nk = block[k]
        self[nk]=delete(k) if nk
      end
    else
      raise ArgumentError, "3 for 2" if block
      to, from = *args
      self[to] = self.delete(from) if self.has_key?(from)
    end
    self
  end

  # Apply a block to hash, and recursively apply that block
  # to each subhash.
  #
  #   h = {:a=>1, :b=>{:b1=>1, :b2=>2}}
  #   h.recursively{|h| h.rekey(&:to_s) }
  #   => {"a"=>1, "b"=>{"b1"=>1, "b2"=>2}}
  #
  def recursively(&block)
    h = inject({}) do |hash, (key, value)|
      if value.is_a?(Hash)
        hash[key] = value.recursively(&block)
      else
        hash[key] = value
      end
      hash
    end
    yield h
  end

  def symbolize_keys
    hash = self.dup
    hash.each do |k,v| 
      sym = k.respond_to?(:to_sym) ? k.to_sym : k 
      hash[sym] = Hash === v ? v.symbolize_keys : v 
      hash.delete(k) unless k == sym
    end
    hash
  end

  # Merges self with another hash, recursively.
  # http://gemjack.com/gems/tartan-0.1.1/classes/Hash.html
  def deep_merge(hash)
    target = dup
    
    hash.keys.each do |key|
      if hash[key].is_a? Hash and self[key].is_a? Hash
        target[key] = target[key].deep_merge(hash[key])
        next
      end
      
      target[key] = hash[key]
    end
    
    target
  end

  # Same as normal deep_merge but coerces
  # values into the same data type as the original
  # and removing blank values
  def coercive_deep_merge(hash)
    target = dup
    
    hash.keys.each do |key|
      if hash[key].is_a? Hash and self[key].is_a? Hash
        target[key] = target[key].coercive_deep_merge(hash[key])
        next
      end

      next if hash[key].blank?

      target[key] = 
        if target[key].kind_of? Array
          v = hash[key]
          if v.kind_of?(String)
            v.split(/\s*,\s*/).map{|i| numeric_value(i)}
          elsif v.kind_of?(Array)
            v.map{|i| numeric_value(i)}
          end
        elsif target[key].kind_of? String
          hash[key].to_s
        elsif target[key].kind_of? Numeric
          numeric_value(hash[key])
        elsif target[key].kind_of?(FalseClass) or target[key].kind_of?(TrueClass)
          boolean_value(hash[key])
        else
          hash[key]
        end
    end
    
    target
  end

  protected

  # Attempt to convert to a numeric value, failing that return a string
  def numeric_value(v)
    v.strip!
    return v unless v =~ /^[\d\.]+$/
    !!v.include?(".") ? v.to_f : v.to_i
  end

  def boolean_value(v)
    v && v != "false" && v != "0" && v != 0 ? true : false
  end

end




