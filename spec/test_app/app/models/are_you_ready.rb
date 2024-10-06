class AreYouReady < Struct.new(:are_you_ready, keyword_init: true)
  def ready?(**params) = are_you_ready
end
