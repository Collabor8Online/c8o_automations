module Automations
  def self.always = @always ||= Always.new

  class Always
    def ready?(**) = true

    def to_h = {}

    def to_s = "Always"
  end
end
