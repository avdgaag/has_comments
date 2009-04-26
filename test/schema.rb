ActiveRecord::Schema.define(:version => 0) do
  create_table :posts, :force => true do |t|
    t.string :title
    t.integer :comments_count, :approved_comments_count
    t.timestamps
  end

  create_table :comments, :force => true do |t|
    t.string :name, :email, :url, :commentable_type
    t.text :body
    t.datetime :approved_at
    t.integer :user_id, :commentable_id
    t.timestamps
  end
end