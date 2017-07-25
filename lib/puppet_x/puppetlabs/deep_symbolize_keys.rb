class Object
  def deep_symbolize_keys
    if is_a? Hash
      return reduce({}) do |memo, (k, v)|
        memo.tap { |m| m[k.to_sym] = v.deep_symbolize_keys }
      end
    end
    if is_a? Array
      return each_with_object([]) do |v, memo|
        memo << v.deep_symbolize_keys
      end
    end
    self
  end
end
