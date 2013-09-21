require 'active_support/core_ext'
require 'mailjet'

class Mailer
  
  def initialize(email_config)
    # set SSL_CERT_FILE=cacert.pem to make it work.
    # https://gist.github.com/mislav/5026283
    
    Mailjet.configure do |config|
      config.api_key = email_config.mailjet_key
      config.secret_key = email_config.mailjet_secret
      config.default_from = email_config.mailjet_from
    end
  end

  def test(source_name, date, base_url, articles)
    mail = MailBuilder.new(source_name, date, base_url)

    title = "[MediaMp3] " + mail.title
    campaign = Mailjet::Campaign.create(title: title, 
                                        subject: title, 
                                        from: Mailjet.config.default_from,
                                        from_name: 'MediaMp3', 
                                        lang: 'fr',
                                        edition_mode: 'html',
                                        footer: 'default',
                                        permalink: 'default')

    campaign.set_html(mail.build(articles)) 
    p campaign
    
  end
    
end