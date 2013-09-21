require 'json'

class Article
  attr_reader :source, :date, :url
  attr_accessor :id, :title, :content, :html
  
  def initialize(source, date, url)
      @source = source
      @date = date
      @url = url
  end
  
  def save()
    filename = path('json')
    puts "Saving '#{title}' in #{filename} ..."
    File.open(filename, 'w') do |f|
       f.write JSON.pretty_generate(self)
    end
  end  
  
  def basepath
    return "#{date}/#{source}"
  end
  
  def path(ext)
    return "#{basepath}/#{id}.#{ext}"
  end
  
  def mp3_link(base_url)
    return "#{base_url}/#{basepath}/#{id}.mp3"
  end

  def self.json_create(json)
    a = new(json['source'],json['date'], json['url'])
    json.each do |var, value|
      a.instance_variable_set "@#{var}", value unless ['url', 'source', 'date', 'json_class'].include?(var)
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
  
  def to_s
    "#{id} - #{title} (#{url})."
  end
  
  def eql?(other)
    title.eql?(other.title)
  end
  
  def hash()
    title.nil? ? id.hash : title.hash
  end
end