require 'rubygems'
require 'bundler/setup'
require 'thor'
require 'aws-sdk'

$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'
require 'article'
require 'media_encoder'

 
class MediaMp3 < Thor
  class_option :date, :default => Time.new.strftime('%Y%m%d')
  class_option :force, :type => :boolean, :default => false

  option :user
  option :password
  desc "crawl SOURCE", "Crawl HTML source website to get all article on txt format."
  def crawl(source)    
    # TODO: Check for invalid source.
    
    require "crawler/#{source}"
    crawler_klass = Kernel.const_get(camelize(source))      
    
    crawler = nil
    if options[:user].nil?
      crawler = crawler_klass.new
    else
      # TODO: Check both user and password have been provided
      crawler = crawler_klass.new(options[:user], options[:password])
    end
    
    path = calculate_path(options[:date], source)
    FileUtils.remove_entry(path, true) if options[:force]
    FileUtils.mkdir_p(path) unless File.exists?(path)

    puts "Crawling: #{crawler.source}"
    articles = crawler.crawl(options[:date])
    articles.each { |a| a.save(path) }
  end
  
  
  desc "encode SOURCE", "Convert all articles from a source to mp3."
  def encode(source)
    path = calculate_path(options[:date], source)
      
    # TODO: Check articles have been crawled previously.

    encoder = MediaEncoder.new(path)
    Dir["#{path}/*.json"].each do |f|
      article = JSON.load(File.new(f))
      mp3_filename = article.full_path(path).sub('.json', '.mp3')
      if options[:force] || ! File.exists?(mp3_filename)
        encoder.encode(article)
      end
    end  
  end
  
  option :aws_login, :required => true
  option :aws_password, :required => true
  desc "upload SOURCE", "Upload mp3 files to Amazon S3."
  def upload(source)
    path = calculate_path(options[:date], source)
     
    s3 = AWS::S3.new(
      :access_key_id => options[:aws_login], 
      :secret_access_key => options[:aws_password])
    bucket = s3.buckets['mediamp3']
     
    Dir["#{path}/*.mp3"].each do |filename|
      object = bucket.objects[filename]
      unless object.exists?
        puts "Uploading #{filename}..."
        object.write(:file => filename)
        object.acl = :public_read
      end
    end
    
  end

  desc "email SOURCE", "Send email with links to mp3."
  def email(source)
    path = calculate_path(options[:date], source)
    
  end
  
  no_commands do
    def camelize(str)
      str.split('_').map {|w| w.capitalize}.join
    end

    def calculate_path(date, source)
      "#{date}/#{source}"
    end
  end

end
 
MediaMp3.start(ARGV)
