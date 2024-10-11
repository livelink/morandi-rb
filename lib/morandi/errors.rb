# frozen_string_literal: true

module Morandi
  class Error < StandardError
  end

  class CorruptImageError < Error
  end

  class UnknownTypeError < Error
  end
end
