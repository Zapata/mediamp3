require 'nokogiri'

class MailBuilder
  attr_reader :title
  
  def initialize(source_name, date, base_url)
    @title = "#{source_name} du #{Date.parse(date).strftime('%d/%m/%Y')}"
    @base_url = base_url
  end
  
  def build(articles)
    builder = Nokogiri::HTML::Builder.new do |doc|
      doc.html {
        doc.head {
          doc.meta(:content => "text/html; charset=utf-8", 'http-equiv' => "Content-Type")
          doc.title title
        }
        doc.body {
          doc.h1 title
          doc.ul {
           articles.each do |article|
              doc.li {
                doc.a(:href => article.mp3_link(@base_url)) {
                  doc.text article.title
                }
              }
           end
          }
          doc.p(:style=>"text-align: center") {
            doc.text "Cet email a été envoyé à "
            doc.a(:href => "mailto:[[EMAIL_TO]]") {
              doc.text '[[EMAIL_TO]]'
            }
            doc.text ', cliquez '
            doc.a(:href =>"[[UNSUB_LINK_FR]]") {
              doc.text 'ici'
            }
            doc.text ' pour vous désabonner.'
          }
        }
      }
    end
    return builder.to_html.gsub('%5B', '[').gsub('%5D', ']')
  end
end