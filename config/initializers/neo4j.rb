NEO4J_CONFIG = YAML.load_file("#{Rails.root}/config/neo4j.yml")[Rails.env]
NEO4J_BASE_URI = "http://#{NEO4J_CONFIG["server"]}:#{NEO4J_CONFIG["port"]}#{NEO4J_CONFIG["path"]}"