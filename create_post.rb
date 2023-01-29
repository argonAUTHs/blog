if ARGV.length != 1
  abort('usage: ruby create_post.rb "some post title"')
end

require 'time'
require "stringex"

title = ARGV[0]
date = Time.now.strftime('%Y-%m-%d')
filename = "_posts/#{date}-#{title.to_url}.markdown"

if File.exist?(filename)
  abort("#{filename} already exists!")
end

puts "Creating new post: #{filename}"
open(filename, 'w') do |post|
  post.puts "---"
  post.puts "title: \"#{title.gsub(/&/,'&amp;')}\""
  post.puts "date: #{Time.now.iso8601}"
  post.puts "layout: post"
  post.puts "authors:"
  post.puts " -"
  post.puts "tags:"
  post.puts " -"
  post.puts "---"
end

puts "vim #{filename}"
