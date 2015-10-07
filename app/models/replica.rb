class Replica < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "redshift_#{Rails.env}".to_sym
end
