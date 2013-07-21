require 'json'

class Article
  attr_reader :id, :source
  attr_accessor :title, :content, :html
  
  def initialize(id, source)
      @id = id
      @source = source
  end
  
  def save(path)
    filename = "#{path}/#{id}.json"
    puts "Saving '#{title}' in #{filename} ..."
    File.open(filename, 'w') do |f|
       f.write JSON.pretty_generate(self)
    end
  end  
  
  def self.json_create(json)
    a = new(json['id'], json['source'])
    json.each do |var, value|
      a.instance_variable_set "@#{var}", value unless ['id', 'source', 'json_class'].include?(var)
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
end