# -*- encoding : utf-8 -*-

require_relative 'crawler'

class VingtMinutes < Crawler
  public
  def source
     return :vingt_minutes
  end
  
  protected
  def base_url(date)
      return "http://www.20minutes.fr/actus"
  end
  
  def should_keep_link(link, date) 
    link.path =~ /\d+-#{date}-/
  end
  
  def extract_id(url, date) 
    m = url.path.match(/(\d+)-#{date}-/)
    m.nil? ? nil : m[1] 
  end
  
  def clean_text(text)
    text = super
    text.gsub(/\.([^\.])/, '. \1')
  end
  
  def extract_article(page, date)
    article = Article.new(page.url, source)
    article.id = extract_id(page.url, date)
    doc = page.doc
    unless doc.nil?
      article.html = doc.to_html
      article.title = clean_text(doc.xpath("//div[@class='mn-left']/h1").text)
      doc.xpath("//div[@class='mna-body']").each do |body|
        body.xpath('script').remove
        body.xpath('div').remove
        article.content = clean_text(body.text)
      end
    end
                
    return article
  end
end
