class Talent < Node
  include HTTParty
  base_uri NEO4J_BASE_URI
  attr_accessor :bands






end
