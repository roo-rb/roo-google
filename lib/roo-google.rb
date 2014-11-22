require 'roo'
require 'roo/google'

module Roo
  CLASS_FOR_EXTENSION.merge! google: ::Roo::Google
end
