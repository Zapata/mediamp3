require 'json'

class Article
  attr_reader :url, :source
  attr_accessor :id, :title, :content, :html
  
  def initialize(url, source)
      @url = url
      @source = source
  end
  
  def save(path)
    filename = path(path, 'json')
    puts "Saving '#{title}' in #{filename} ..."
    File.open(filename, 'w') do |f|
       f.write JSON.pretty_generate(self)
    end
  end  
  
  def path(basepath, ext)
    return "#{basepath}/#{id}.#{ext}"
  end

  def self.json_create(json)
    a = new(json['url'], json['source'])
    json.each do |var, value|
      a.instance_variable_set "@#{var}", value unless ['url', 'source', 'json_class'].include?(var)
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
end