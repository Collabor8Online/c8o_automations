# Configuration for the "Review documents" automation
class ReviewDocuments < Struct.new(:statuses, keyword_init: true)
  def ready? **params
    params.key?(:documents) && params[:documents].any? { |d| statuses.include? d.status }
  end
end
