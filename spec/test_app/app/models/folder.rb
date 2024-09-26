class Folder < ApplicationRecord
  scope :roots, -> { where(parent: nil) }
  belongs_to :project, class_name: "Automatable"
  belongs_to :parent, class_name: "Folder", optional: true
  has_many :children, class_name: "Folder", foreign_key: "parent_id", dependent: :destroy
  has_many :documents, dependent: :destroy
  validates :name, presence: true

  def sibling_called name
    parent.nil? ? project.folders.roots.find_by(name: name) : parent.children.find_by(name: name)
  end
end
