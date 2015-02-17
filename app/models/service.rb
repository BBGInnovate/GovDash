class Service < ActiveRecord::Base
  validates :name, length: { in: 2..40 }
#  validates_numericality_of :network_id, :on => :create
  
  belongs_to :network
  has_many :accounts

  def self.populate
    # place holder
  end
  
  def self.find_me(name, network_name)
    nid = Network.find_by_name(network_name).id
    where("name='#{name}' AND network_id=#{nid}").first
  end
end

