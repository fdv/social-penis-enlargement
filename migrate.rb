class CreateUser < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.integer :user_id, :limit => 8
      t.string :screen_name
      t.boolean :following, :default => false
      t.boolean :followed, :default => false
      t.boolean :unfollowed, :default => false
      t.timestamp :followed_at
      t.timestamp :created_at
      t.timestamp :updated_at
      t.boolean :keep
      t.text :twitter_attributes
    end
  end
end

