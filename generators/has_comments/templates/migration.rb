class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments, :force => true do |t|
      # Content
      t.string    :name,              :size => 200
      t.string    :email,             :size => 200
      t.string    :url,               :size => 200
      t.text      :body,              :null => false

      # Management features
      t.datetime  :approved_at
      t.boolean   :spam,              :default => false

      # Relation to other models
      t.integer   :user_id
      t.integer   :commentable_id,    :null => false
      t.string    :commentable_type,  :null => false

      # Other
      t.timestamps
    end

    # Indices
    add_index :comments, :commentable_id
    add_index :comments, :commentable_type
    add_index :comments, :user_id
    add_index :comments, :approved_at
  end

  def self.down
    drop_table :comments
  end
end