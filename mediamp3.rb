require 'rubygems'
require 'bundler/setup'
require 'thor'
require 'aws-sdk'
require 'configuration'

require_relative 'lib/article'
require_relative 'lib/media_encoder'

class MediaMp3 < Thor
  class_option :date, :default => Time.new.strftime('%Y%m%d'), :desc => 'Wich date to work on?'
  class_option :force, :type => :boolean, :default => false, :desc => 'Force to redo the action.'
    
  desc "crawl SOURCE", "Crawl HTML source website to get all article on txt format."
  def crawl(source)    
    check_sources(source)

    require_relative "lib/crawler/#{source}"
    crawler_klass = Kernel.const_get(camelize(source))      
    
    source_config = @config.crawler.method(source).call
    user = source_config.respond_to?(:user) ? source_config.user : nil
    password = source_config.respond_to?(:password) ? source_config.password  : nil
      
    crawler = nil
    if user.nil?
      crawler = crawler_klass.new
    else
      crawler = crawler_klass.new(user, password)
    end
    
    path = calculate_path(options[:date], source)
    FileUtils.remove_entry(path, true) if options[:force]
    FileUtils.mkdir_p(path) unless File.exists?(path)

    puts "Crawling: #{crawler.source}"
    articles = crawler.crawl(options[:date]) { |a| a.save(path) }
  end
  
  
  desc "encode SOURCE", "Convert all articles from a source to mp3."
  def encode(source)
    check_sources(source)
    path = calculate_path(options[:date], source)
    
    encoder = MediaEncoder.new()
    on_articles(path) do |article|
      if options[:force] || ! File.exists?(article.path(path, 'mp3'))
        encoder.encode(path, article)
      end
    end  
  end
  
  desc "upload SOURCE", "Upload mp3 files to Amazon S3."
  def upload(source)
    check_sources(source)
    path = calculate_path(options[:date], source)
     
    s3 = AWS::S3.new(
      :access_key_id => @config.aws.access_key_id, 
      :secret_access_key => @config.aws.secret_access_key)
    bucket = s3.buckets['mediamp3']
    puts "Start upload to: #{bucket.url}"
    
    on_articles(path) do |article|
      filename = article.path(path, 'mp3')
      object = bucket.objects[filename]
      unless object.exists?
        puts "Uploading #{filename}..."
        object.write(:file => filename, :content_type => 'audio/mpeg')
        object.acl = :public_read
      end
    end
    
  end

  desc "email SOURCE", "Send email with links to mp3."
  def email(source)
    check_sources(source)
    path = calculate_path(options[:date], source)
    
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
    
    def on_articles(path)
      Dir["#{path}/*.json"].each do |f|
        article = JSON.load(File.new(f))
        yield article
      end
    end
  end
  
  def initialize(*args)
    super
    @config = Configuration.load 'config'
  end
end
 
MediaMp3.start(ARGV)
