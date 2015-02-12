module Rabbit

  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def conf
      @conf ||= YAML::load_file(File.join(Rails.root.to_s, 'config/rabbit.yml'))[Rails.env].symbolize_keys
    end
  end # module ClassMethods

end