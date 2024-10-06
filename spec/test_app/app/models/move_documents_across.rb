# Handler for the "move documents to review folder" action
class MoveDocumentsAcross < Struct.new(:folder_name, keyword_init: true)
  def call(documents:, folder:, **)
    raise FolderNotFound if (destination_folder = folder.sibling_called(folder_name)).nil?
    # This is a bit nasty - have to convert to an array because if we are given an ActiveRecord relation for "all documents in folder X" then the relation will update itself to be empty after we move the documents out of that folder
    documents = documents.collect { |d| d.update!(folder: destination_folder) && d }
    {documents: documents, folder: destination_folder}
  end
end
