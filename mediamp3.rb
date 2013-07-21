$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'
require 'crawler/lequipe'
require 'article'
require 'media_encoder'

# Crawl articles (to write)
path = Time.new.strftime('%Y%m%d')
unless File.exists?(path)
  lequipe = Lequipe.new
  lequipe.connect('*****', '*****')
  lequipe.crawl(path)  
end

# Convert to Test to mp3 (balabolka + lame)
encoder = MediaEncoder.new(path)
Dir["#{path}/*.json"].each do |article_file|
  article = JSON.load(File.new(article_file))
  encoder.encode(article)
end

# Send email