require "ltsv/version"

module LTSV

  def parse(io_or_string, options = {})
    case io_or_string
    when String
      parse_string(io_or_string, options)
    when IO
      parse_io(io_or_string = {})
    end
  end

  def load(io_or_string, options = {})
    encoding_opt = options.delete :encoding
    encoding =
      encoding_opt ? Encoding.find(encoding_opt) : Encoding.default_external

    case io_or_string
    when String
      File.open(io_or_string, "r:#{encoding}"){|f|parse_io(f)}
    when IO
      parse_io(io)
    end
  end

  def dump(object)
    raise ArgumentError, "dump should take an argument of hash" unless object.kind_of? Hash

    object.inject('') do |s, kv|
      s << "\t" if s.bytesize > 0

      (k, v) = kv
      value = escape v
      s << k.to_s << ':' << value
    end
  end

  private

  def parse_io(io, options)#:nodoc:
    io.map{|l|parse_string l, options}
  end

  def parse_string(string, options)#:nodoc:
    symbolize_keys = options.delete(:symbolize_keys)
    symbolize_keys = true if symbolize_keys.nil?

    string.split("\t").inject({}) do |h, i|
      (key, value) = i.split(':', 2)
      key = key.to_sym if symbolize_keys
      unescape!(value)
      h[key] = value
      h
    end
  end

  def unescape!(string)#:nodoc:
    return nil if !string || string == ''

    string.gsub!(/\\([a-z\\])/) do |m|
      case m[1]
      when 'r'
        "\r"
      when 'n'
        "\n"
      when 't'
        "\t"
      when '\\'
        '\\'
      else
        m[0]
      end
    end
  end

  def escape(string)#:nodoc:
    value = string.kind_of?(String) ? string.dup : string.to_s

    value.gsub!("\\", "\\\\")
    value.gsub!("\n", "\\n")
    value.gsub!("\r", "\\r")
    value.gsub!("\t", "\\t")

    value
  end

  module_function :load, :parse, :dump, :parse_io, :parse_string, :unescape!, :escape

  class <<self
    private :parse_io, :parse_string, :unescape!, :escape
  end
end
