# Handler for the "notify the reviewer" action
class NotifyReviewer < Struct.new(:email_address, keyword_init: true)
  def call(documents:, folder:, **)
    # TODO: ReviewerMailer.with(documents: documents, folder: folder, recipient: email_address).documents_awaiting_review.deliver_later
    {documents: documents, folder: folder, reviewer: email_address}
  end
end
