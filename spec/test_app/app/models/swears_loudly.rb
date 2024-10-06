class SwearsLoudly < Struct.new(:expletive, keyword_init: true)
  def call(**params) = {response: expletive.to_s}
end
