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
          doc.text "Cher(e) abonné(e) MediaMp3,"
          doc.br
          doc.br
          doc.text "Voici le sommaire du journal #{title} : "
          doc.ul {
           articles.each do |article|
              doc.li { 
                doc.text "#{article.title} : "
                doc.a(:href => article.mp3_link(@base_url)) {
                  doc.text 'écouter'
                }
              }
           end
          }
          
          doc.p {
            doc.text "MediaMp3 est une startup développant un outil de transformation de la presse quotidienne "
            doc.text "écrite (L'équipe, 20minutes, le Parisien, le Monde ...) en fichiers audio .mp3. "
            doc.text "C’est le même concept que le livre audio, appliqué à la presse quotidienne."
          }
          
          doc.p {
            doc.text "Nous gérons actuellement L'équipe et le 20 minutes. "
            doc.text "Si vous êtes intéressés pour recevoir ces journaux quotidiennement, repondez à cet email."
          }

          doc.p {
            doc.text "Nous sommes actuellement en phase de lancement tout feedback sur le service est le bienvenu."
          }
                    
          doc.p(:style=>"text-align: center") {
            doc.b "MediaMp3 : ton journal, tu écouteras!"
            doc.br
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