class Node
  include HTTParty
  #headers  'ContentType' => 'application/json' ,'Accept' => 'text/html'
  headers 'content-type' => 'application/json'
  base_uri NEO4J_BASE_URI
  format :json
  
  require 'roo'
  require 'iconv'
  
  attr_accessor :data, :id, :type, :rels
  
  class << self
    
    def redo
      Node.remove_all_properties(1000)
      Node.update(1000,{:a=>Time.now.to_i})
    end
    
    def remove_all_properties(id)
      Node.delete("/node/#{id}/properties")
    end
    
    def update(id, hash)
      Node.put("/node/#{id}/properties", :body=>hash)
    end

    def create(hash={})
      Node.post("/node", :body=>hash)
    end
    
    def add_indicies(start=73)
      start.upto(19000).each do |id|
        node = Node.find(id)
      end
    end
    
    def insert_nodes
      gcdm_info = Excel.new("/Users/robertjenkins/projects/talent_tracker/info/gcdm_info.xls")
      gcdm_info.sheets.each do |sheet|
        next if ["RIGHTS TERRITORIES","ROLES","TALENT-ROLE-ENTITY","ASSET-WORK"].include? sheet
        header= gcdm_info.row(1, sheet)
        header= header.collect do |value| value.downcase end
        type  = sheet.singularize.downcase.gsub("-","_")
        
        2.upto(gcdm_info.last_row(sheet)) do |line|
          row_data = Hash[*header.zip(gcdm_info.row(line,sheet)).flatten]
          row_data.delete_if do |key, value| key.index(/id$/) || key == "entity" end
          id = gcdm_info.cell(line,"a", sheet)
          id = id.to_i if id.kind_of? Float
          row_data["guid"] = "#{type}#{id}"
          row_data["type"] = type
          row_data.map do |key, value|
            if value.blank?
              row_data[key] = 0
            else
              row_data[key] = value
            end
          end

          begin
            puts "#{(JSON.parse(Node.create(row_data).body))["self"]} => #{row_data["guid"]}"
          rescue
            error = "failed to create #{row_data}"
            puts error
            Rails.logger.debug error
          end
        end
      end
    end


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
  
  
  def response(depth=0, traversed=[])
    self.data.merge(self.related(depth, traversed))
  end
  
  def uri
    "#{NEO4J_CONFIG["path"]}/node/#{id}"
  end
    
    
    
  def origin(depth=2)
    {:origin => self.data}.merge(self.related(depth))
  end
  
  def make_index
    Node.post("/index/node/guid_translation", :body=>{
      :key=>self.guid.match(/([a-z]+)/)[1],
      :value=>self.guid.match(/([0-9]+)/)[1],
      :uri=>self.uri})
  end
  
  
  def related(depth=0, traversed=[])
    puts "#{traversed.inspect}=>#{self.id}"
    @related = Hash.new
    self.relationships.each do |relationship|
      #puts "\n#{relationship.inspect}\n"
      next if traversed.include? relationship.node(self.id)
      #next if relationship.direction(self.id) == "in"
      clean = "#{relationship["type"].gsub(" ", "_")}_#{relationship.direction(self.id)}"
      @related[clean] ||= Array.new
      if depth > 0
        @related[clean] << Node.find(relationship.node(self.id)).response(depth-1, (traversed<<self.id).uniq)
      else
        @related[clean] << relationship.url(self.id)
      end
    end
    @related
  end
  
  
  
  def initialize(hash={})
    self.data ||= Hash.new
    if hash.has_key?(:id)
      self.data["id"] = hash[:id].to_i
      self.id = hash[:id].to_i
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
  
  
  def method_missing(value, *args)
    return @data[value.to_s] if @data.keys.include?(value.to_s)
    raise NoMethodError, "undefined method `#{value}' for xxx:#{self.class}"
  end
  
  
end
