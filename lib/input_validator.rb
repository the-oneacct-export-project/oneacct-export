require 'uri'

# Simple helper module for input validation
module InputValidator
  URI_RE = /\A#{URI.regexp}\z/
  NUMBER_RE = /\A[[:digit:]]+\z/
  STRING_RE = /\A[[:print:]]+\z/
  NON_ZERO_NUMBER_RE = /\A[1-9][[:digit:]]*\z/

  def is?(object, regexp)
    object.to_s =~ regexp
  end

  def is_number?(object)
    is?(object, NUMBER_RE)
  end

  def is_uri?(object)
    is?(object, URI_RE)
  end

  def is_string?(object)
    is?(object, STRING_RE)
  end

  def is_non_zero_number?(object)
    is?(object, NON_ZERO_NUMBER_RE)
  end
end
