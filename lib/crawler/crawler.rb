# -*- encoding : utf-8 -*-

require 'set'
require 'uri'
require 'cgi'
require 'net/http'
require 'anemone'
require 'nokogiri'
require 'article'

class Crawler
  public
  
  def crawl(date)
    unique_articles = Set.new
    
    Anemone.crawl(base_url(date), options) do |anemone|
      
      anemone.focus_crawl do |page| 
        page.links.select { |l| should_keep_link(l, date) }
      end
      
      anemone.on_every_page do |page|
        article = extract_article(page, date)
        unique_articles << article if valid(unique_articles, article)
      end
    end
    
    return unique_articles.to_a()
  end
  
  protected
  
  def options
    return {}
  end
  
  def clean_text(str)
    str = str.gsub(/\s+/, ' ') # Remove spaces and new lines
    # Remove non printable chars.
    # printable_chars = str.codepoints.to_a.find_all { |i| i <= 0xFF || "«’€".codepoints.include?(i) }
    printable_chars = str.codepoints.to_a.find_all { |i| not [ 8202, 8201 ].include?(i) }
    return printable_chars.pack("U*")
  end
  
  private
  
  def valid(unique_article, article)
    if article.id.nil? || article.title.nil? || article.content.nil?
      puts "Invalid article: #{article.to_s}"
      return false
    end
  
    if article.content.size < 100
      puts "Skip article because too few characters (#{article.content.size}): #{article.to_s}"
      return false
    end

    if unique_article.include?(article)
      puts "Skip article as it's a duplicate: #{article.to_s}"
      return false
    end

    puts "Good Article: #{article.to_s}"
    return true
  end

end