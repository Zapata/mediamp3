# -*- encoding : utf-8 -*-

# Get articles (to write)

require 'uri'
require 'cgi'
require 'set'
require 'net/http'
require 'nokogiri'
require 'anemone'
require 'fileutils'
require 'json'

class Article
  attr_reader :id, :source
  attr_accessor :title, :content, :html
  
  def initialize(id, source)
      @id = id
      @source = source
  end
  
  def save(path)
    filename = "#{path}/#{id}.json"
    puts "Saving '#{title}' in #{filename} ..."
    File.open(filename, 'w') do |f|
       f.write JSON.pretty_generate(self)
    end
  end  
  
  def self.json_create(json)
    a = new(json['id'], json['source'])
    json.each do |var, value|
      self.instance_variable_set var, value unless ['id', 'source', 'json_class'].include?(var)
    end
    return a
  end

  def as_json
    hash = {}
    hash['json_class'] = self.class.name
    self.instance_variables.each do |var|
      hash[var.to_s.sub('@', '')] = self.instance_variable_get var
    end
    return hash
  end
  
  def to_json(*a)
    as_json.to_json(*a)
  end
end

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
  
  def extract_cleaned_content(body)
    content = body.text
    clean_text(content)
  end  
  
  def extract_article(page, path)
    id = extract_id(page.url)
    return nil if id.nil?
    doc = page.doc
    
    article = Article.new(id, :lequipe)
    article.html = doc.to_html
    
    doc.xpath("//p[@class='DtxTexte']/..").each do |body|
      article.title = extract_title(body)
      article.content = extract_cleaned_content(body)
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
  
  def crawl()
    raise 'Please connect first.' if @session.nil?
    
    @unique_article = Set.new
    
    path = Time.new.strftime('%Y%m%d')
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


lequipe = Lequipe.new

lequipe.connect('*****', '*******')
lequipe.crawl()

#id = "EQ_130719_2-1-0-160583348_2"
#doc = Nokogiri::HTML(open("http://www.lequipe.fr/Quotidien/article_html.php?ID=#{id}", 'Cookie' => "PHPSESSID=eeim97jq61u87b9ks2bhghfev0"))
#lequipe.save_article(doc, id)

# Convert Text (optional: use balabolka_text)

# Convert to Test to mp3 (balabolka + lame)

# Send email