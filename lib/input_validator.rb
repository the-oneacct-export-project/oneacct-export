require 'uri'

module InputValidator
  URI_RE = /\A#{URI.regexp}\z/
  NUMBER_RE = /\A[[:digit:]]+\z/

  def is?(object, regexp)
    object.to_s =~ regexp
  end

  def is_number?(object)
    is?(object, NUMBER_RE)
  end

  def is_uri?(object)
    is?(object, URI_RE)
  end
end

