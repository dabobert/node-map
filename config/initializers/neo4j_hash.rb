class Hash

  def direction(id)
    node_url = "#{NEO4J_BASE_URI}/node/#{id}"
    if self["start"] == node_url && self["end"] == node_url
      "both"
    elsif self["start"] == node_url
      "out"
    elsif self["end"] == node_url
      "in"
    end
  end
  
  
  def node(id)
    case self.direction(id)
    when "in"
      self["start"]
    when "out"
      self["end"]
    else
      self["end"]
    end
  end
  
end