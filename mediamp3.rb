require 'rubygems'
require 'bundler/setup'

require 'thor'
require 'configuration'

require_relative 'lib/article'
require_relative 'lib/media_encoder'
require_relative 'lib/storage'
require_relative 'lib/mail_builder'
require_relative 'lib/mailer'

class MediaMp3 < Thor
  class_option :date, :default => Time.new.strftime('%Y%m%d'), :desc => 'Wich date to work on?'
  class_option :force, :type => :boolean, :default => false, :desc => 'Force to redo the action.'
    
  desc "crawl SOURCE", "Crawl HTML source website to get all article on txt format."
  def crawl(source)    
    check_sources(source)

    # Fixme: move this in cralwer.rb
    require_relative "lib/crawler/#{source}"
    crawler_klass = Kernel.const_get(camelize(source))      
    
    crawler = crawler_klass.new
    if crawler.respond_to?(:login)
      crawler.login(source_config(source).user, source_config(source).password) 
    end
    
    path = calculate_path(options[:date], source)
    FileUtils.remove_entry(path, true) if options[:force]
    FileUtils.mkdir_p(path) unless File.exists?(path)

    articles = crawler.crawl(options[:date]) { |a| a.save }
  end
  
  desc "encode SOURCE", "Convert all articles from a source to mp3."
  def encode(source)
    check_sources(source)
    
    encoder = MediaEncoder.new()
    on_articles(options[:date], source) do |article|
      if options[:force] || ! File.exists?(article.path('mp3'))
        encoder.encode(article)
      end
    end  
  end
  
  desc "upload SOURCE", "Upload mp3 files to Amazon S3."
  def upload(source)
    check_sources(source)
    
    s = Storage.new(@config.storage)
    on_articles(options[:date], source) do |article|
      s.upload(article)
    end
  end

  desc "mail_generate SOURCE", "Send email with links to mp3."
  def mail_generate(source)
    check_sources(source)

    articles = []
    on_articles(options[:date], source) { |a| articles << a }
    
    m = MailBuilder.new(source_config(source).name, options[:date], @config.storage.base_url)
    puts m.build(articles)
  end
  
  desc "mail SOURCE", "Create a campaign and send emails with articles through MailJet."
  method_option :contact_list, :type => :string, :desc => 'Mailjet contact list to send mail to.'
  def mail(source)
    check_sources(source)

    articles = []
    on_articles(options[:date], source) { |a| articles << a }

    contact_list = options[:contact_list] || @config.email.mailjet_list

    m = Mailer.new(@config.email)
    m.send(source_config(source).name, options[:date], @config.storage.base_url, articles, contact_list)
  end
  
  
  
  no_commands do
    def camelize(str)
      str.split('_').map {|w| w.capitalize}.join
    end

    def calculate_path(date, source)
      "#{date}/#{source}"
    end
    
    def check_sources(source)
      source_extractor = /lib\/crawler\/(?<source>.*)\.rb/
      available_sources = Dir.glob('lib/crawler/*.rb').collect { |s| source_extractor.match(s)[:source] }
      available_sources.delete('crawler')
      
      unless available_sources.include?(source)
        raise MalformattedArgumentError, "Expected 'source' to be one of #{available_sources.join(', ')}; got #{source}"
      end
    end
    
    def on_articles(date, source)
      Dir["#{calculate_path(date, source)}/*.json"].each do |f|
          article = JSON.load(File.new(f))
          yield article
      end
    end
    
    def source_config(source)
      @config.crawler.method(source).call
    end
  end
  
  def initialize(*args)
    super
    @config = Configuration.load 'config'
  end
end
 
MediaMp3.start(ARGV)
