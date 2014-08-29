require 'twitter'
require 'json'

class User < ActiveRecord::Base
  attr_accessible :user_id, :following
  def self.init(username)
    client = authenticate(AUTH_KEYS[0])

    CreateUser.migrate(:up)
    
    f = client.friend_ids(username).to_a
    f.each do |user|
      User.create(user_id: user, following: true, keep: true)
    end
    
    puts "Added #{f.size} users"
  end

  def self.fix_followed(username)
    client = authenticate(AUTH_KEYS[1])

    f = client.friends.to_a
  
    f.each do |user|
      u = User.find_by_user_id(user.id)
      unless u.nil?
        u.followed = true
        u.keep = true
        u.twitter_attributes = user.attrs.to_json
        u.save
      else
        User.create(user_id: user, followed: true, twitter_attributes: user.attrs.to_json)
      end
    end
  end

  def self.merge_followers(username)
    client = authenticate(AUTH_KEYS[0])
    
    f = client.follower_ids(username).to_a
    
    f.each do |user|
      u = User.find_by_user_id(user)
      unless u.nil? 
        u.following = true
        u.save
      else
        User.create(user_id: user, following: true)
      end
    end
  end

  def self.fetch_followers(username)
    i = 0    
    next_cursor = -1
    followers = User.find(:all, :select => "user_id")
    mine = followers.map {|i| i.user_id}
    
    while next_cursor != 0
      if i == AUTH_KEYS.size
        sleep 60
        i = 0
      end
      
      client = authenticate(AUTH_KEYS[i])
      cursor = client.follower_ids(username, {cursor: next_cursor})
      his = cursor.attrs[:ids]

      f = his - mine
      puts "\u2714 Adding: #{f.size} users".encode("utf-8").green 
      f.each do |user|
		puts user
        User.create(user_id: user, following: false, followed: false, keep: false, unfollowed: false)
      end
      
      next_cursor = cursor.attrs[:next_cursor]
      i = i + 1
    end
  end

  def self.mass_follow
    users = User.where("following = ? and followed = ? and unfollowed = ?", false, false, false)

    i = 0
    followed = 0
    
    users.each do |user|
      nofollow = false
      
      if i == AUTH_KEYS.size
        sleep 120
        i = 0
      end
      
      client = authenticate(AUTH_KEYS[i])
      begin
        # First, we clean the house a little bit
        u = client.user(user.user_id)
        nofollow = true unless u.lang =~ /fr|en/
        nofollow = true if u.default_profile_image
        nofollow = true if u.description == ""
        noffolow = true if u.protected
        noffolow = true if u.status.created_at < (Time.now - 30.days)
        nofollow = true if u.friends_count.to_f > u.followers_count.to_f
        if u.friends_count.to_f / u.followers_count.to_f < 0.1
          nofollow = true 
          ratio = true
        end
        
        nofollow = true if u.friends_count < 100
        nofollow = true if u.tweets_count < 50
        
        nofollow = false if ratio and u.description =~ /#go|#python|#scala|#mesos/
          
        if nofollow
          puts "\u2717 Ignored #{u.screen_name} (#{user.user_id}) last tweet #{u.status.created_at}".encode("utf-8").red
          user.unfollowed = true
          user.save
        else
          puts "\u2714 Following: #{u.screen_name} (#{user.user_id}) last tweet #{u.status.created_at}".encode("utf-8").green
          user.twitter_attributes = u.attrs.to_json
          client.follow(user.user_id)
          user.followed = true
          user.followed_at = Time.now
          user.screen_name = u.screen_name
          user.save
          followed = followed + 1
        end
      rescue
        user.unfollowed = true
        user.save
      end
      
      return if followed == 950
      i = i + 1
    end  
  end
  
  # Massively unfollow users
  def self.mass_unfollow(counter = 2, following = false)
    i = 0
    users = User.where("keep != ? and followed = ? and followed_at <= ? and following = ? and unfollowed = ?", true, true, counter.days.ago, following, false)
    puts "#{users.count} to unfollow, starting in 5 seconds"
    sleep 5

    users.each do |user|        
      if i == AUTH_KEYS.size
        sleep 60
        i = 0
      end

      client = authenticate(AUTH_KEYS[i])

      begin
        client.unfollow user.user_id
        puts "\u2714 Unfollowed: (#{user.user_id})".encode("utf-8").cyan
      rescue
        puts "ooooops #{user.user_id}"
      end
        user.followed = false
        user.unfollowed = true
        user.save
      i = i + 1
    end
  end
    
  private
  
  def self.authenticate(key)
    Twitter::REST::Client.new do |config|
      config.consumer_key        = key[:consumer_key]
      config.consumer_secret     = key[:consumer_secret]
      config.access_token        = key[:access_token]
      config.access_token_secret = key[:access_token_secret]
    end
  end
end
