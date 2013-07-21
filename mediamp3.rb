$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'
require 'crawler/lequipe'

# Crawl articles (to write)
lequipe = Lequipe.new
lequipe.connect('*****', '*****')
lequipe.crawl(Time.new.strftime('%Y%m%d'))

# Convert to Test to mp3 (balabolka + lame)

# Send email