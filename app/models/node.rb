class Node
  include HTTParty
  base_uri NEO4J_BASE_URI
  format :json
  attr_accessor :data, :id, :type, :rels
  
  class << self

    def find(id)
      data = (JSON.parse(Node.get("/node/#{id}").body))["data"]
      begin
        node = Kernel.const_get(data["type"].camelcase).new(:id=>id, :data=>data)
      rescue
        node = Node.new(:id=>id, :data=>data)
      end  
      node
    end
  
    def relationship_types(id)
      JSON.parse(Node.get("/node/#{id}/relationships/all").body).collect do |a| a["type"] end.compact.uniq
    end

    def test
      JSON.parse Node.get("/node/8/relationships/all").body
    end
    
    def relationships(id)
      JSON.parse(Node.get("/node/#{id}/relationships/all").body)
    end
  
  end
  
  
  def relationships
    JSON.parse(Node.get("/node/#{self.id}/relationships/all").body)
  end
  
  def origin
    #hash          = self.related
    #hash[:origin] = self.data
    #hash
    {
      :origin => self.data,
    }.merge()
  end
  
  def related
    @related = Hash.new
    self.relationships.each do |relationship|
      clean = relationship["type"].gsub(" ", "_")
      @related[clean] ||= Array.new 
      @related[clean] << relationship.node(self.id)
    end
    @related
  end
  
  def initialize(hash={})
    self.data ||= Hash.new
    if hash.has_key?(:id)
      self.data["id"] = hash[:id]
      self.id = hash[:id]
      self.rels = Node.relationships(id).collect do |relationship|
        {:direction=>relationship.direction(self.id), :type=>relationship["type"], :node=>relationship.node(self.id)}
      end
    end
    
    if hash.has_key?(:data)
      self.data.merge!(hash[:data])
      self.type = self.data["type"]
      throw "Rest Mismatch::ruby object is type talent but neo4j node is type #{self.type}" if (self.class.to_s.downcase != self.type && self.class != Node)
    end
  end
  
end
