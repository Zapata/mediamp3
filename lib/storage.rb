require 'aws-sdk'

class Storage
  def initialize(config)
    s3 = AWS::S3.new(
      :access_key_id => config.access_key_id, 
      :secret_access_key => config.secret_access_key)
    @bucket = s3.buckets[config.bucket_name]
    puts "Start upload to: #{@bucket.url}"
  end
  
  def upload(article)
    filename = article.path('mp3')
    object = @bucket.objects[filename]
    unless object.exists?
      puts "Uploading #{filename}..."
      object.write(:file => filename, :content_type => 'audio/mpeg')
      object.acl = :public_read
    end
  end
end