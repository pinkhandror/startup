class AddFileUploadToProduct < ActiveRecord::Migration
  def change
    add_attachment :products, :image
  end
end
