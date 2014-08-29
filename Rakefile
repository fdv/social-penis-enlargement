require './user.rb'

task :merge_followers do
  puts "Merging followers"
  User.merge_followers "fdevillamil"
end

task :fetch_followers do
  User.fetch_followers("fredcavazza")
end

task :purge do
  User.mass_unfollow(0, true)
  User.mass_unfollow(0, false)
end

task :mass_unfollow_without_following do
  User.merge_followers "someaccount"
  User.mass_unfollow
end

task :mass_unfollow_with_following do
  User.merge_followers "someaccount"
  User.mass_unfollow(9, true)
end

task :mass_follow do
  puts "Starting mass follow of 1000 users"
  User.mass_follow
end
