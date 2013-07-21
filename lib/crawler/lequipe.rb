# -*- encoding : utf-8 -*-

require 'uri'
require 'cgi'
require 'set'
require 'net/http'
require 'nokogiri'
require 'anemone'
require 'fileutils'
require 'article'

class Lequipe
  SESSION_PARAM = 'PHPSESSID'
    
  def get_session(cookie_string)
    cookie_as_list = cookie_string.split(/=|; /)
    cookie_map = Hash[*cookie_as_list]
    cookie_map[SESSION_PARAM]
  end

  def connect(user, passwd)
    url = URI.parse('http://www.lequipe.fr')
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Post.new('/v6/php/connect.php')
    request.set_form_data({'query' => 'logged'})
    resp = http.request(request)
    cookies = resp.response['set-cookie']
    @session = get_session(cookies)
    puts "Session: #{@session}"

    request = Net::HTTP::Post.new('/v6/php/connect.php')
    request['Cookie'] = cookies
    request.set_form_data({'query' => 'login', 'login' => user, 'password' => passwd, 'session' => '1'})
    resp = http.request(request)
    raise 'Could not login' unless resp.kind_of?(Net::HTTPSuccess)
  end

  def extract_id(url) 
    unless url.query.nil?
      id = CGI::parse(url.query)['ID']
       return id[0] unless id.nil? || id.size != 1
    end
    return nil
  end
  
  def extract_title(body)
    title_element = body.element_children.find { |e| not e.text.strip.empty? }
    return nil if title_element.nil?
    title = clean_text(title_element.text).strip
    title_element.content = "#{title}."
    title
  end
  
  def clean_text(str)
    str = str.gsub(/\s+/, ' ') # Remove spaces and new lines
    # Remove non printable chars.
    # printable_chars = str.codepoints.to_a.find_all { |i| i <= 0xFF || "«’€".codepoints.include?(i) }
    printable_chars = str.codepoints.to_a.find_all { |i| not [ 8202, 8201 ].include?(i) }
    return printable_chars.pack("U*")
  end
  
  def extract_article(page, path)
    id = extract_id(page.url)
    return nil if id.nil?
    doc = page.doc
    
    article = Article.new(id, :lequipe)
    article.html = doc.to_html
    
    doc.xpath("//td[@class='xt']/p[@class='DtxTexte']/..").each do |body|
      article.title = extract_title(body)
      article.content = clean_text(body.text)
    end
    
    if article.title.nil?
      puts "Invalid article: #{id}"
      return nil
    end
    
    if @unique_article.include?(article.title)
      puts "Skip article '#{article.title}' as it's a duplicate."
      return nil
    else
      @unique_article << article.title
    end
    
    if article.content.size < 100
      puts "Skip article '#{article.title}' too few characters (#{article.content.size})"
      return nil
    end
    
    return article
  end
  
  def crawl(path)
    raise 'Please connect first.' if @session.nil?
    
    @unique_article = Set.new
    FileUtils.mkdir_p(path) unless File.exists?(path)

    opt = { :cookies => { SESSION_PARAM => @session } }
    Anemone.crawl("http://www.lequipe.fr/Quotidien/une_html.php", opt) do |anemone|
      anemone.focus_crawl { |page| page.links.select { |l| l.path =~ /Quotidien/ } }
      anemone.on_every_page do |page|
        article = extract_article(page, path)
        article.save(path) unless article.nil?
      end
    end

  end
end