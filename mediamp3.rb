require 'rubygems'
require 'bundler/setup'

$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'
require 'crawler/lequipe'
require 'crawler/vingt_minutes'
require 'article'
require 'media_encoder'

date = Time.new.strftime('%Y%m%d')

# Crawl articles.
path = date
unless File.exists?(path)
  FileUtils.mkdir(path)

  crawlers = []
  crawlers << Lequipe.new('pasqwale', '******')
  crawlers << VingtMinutes.new
  
  articles = []
  crawlers.each do |crawler|
    puts "Crawling: #{crawler.source}"
    articles += crawler.crawl(date)
  end
    articles.each { |a| a.save(path) }
  
else 
  articles = []
  Dir["#{path}/*.json"].each do |f|
    articles << JSON.load(File.new(f))
  end  
end


# Convert to mp3.
encoder = MediaEncoder.new(path)
articles.each do |a| 
  encoder.encode(a) unless File.exists?(a.full_path(path).sub('.json', '.mp3'))
end

# Store online.

# Send email.