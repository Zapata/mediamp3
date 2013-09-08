# -*- encoding : utf-8 -*-

require 'uri'
require 'cgi'
require 'set'
require 'net/http'
require_relative 'crawler'


class Lequipe < Crawler
  public
  SESSION_PARAM = 'PHPSESSID'
  
  def source
     return :lequipe
  end

  protected
  def base_url(date)
      return "http://www.lequipe.fr/Quotidien/une_html.php"
  end
  
  def should_keep_link(link, date) 
    link.path =~ /Quotidien/
  end

  def initialize(user, passwd)
    connect(user, passwd)
  end
  
  def options
    return { :cookies => { SESSION_PARAM => @session } }
  end
  
  private

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
    
  def extract_article(page, date)
    article = Article.new(page.url, source)
    article.id = extract_id(page.url)
    
    doc = page.doc
    unless doc.nil?
    
      article.html = doc.to_html
      doc.xpath("//td[@class='xt']/p[@class='DtxTexte']/..").each do |body|
        article.title = extract_title(body)
        article.content = clean_text(body.text)
        end
    end
        
    return article
  end
end