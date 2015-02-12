class AccountsScSegment < ActiveRecord::Base
	belongs_to :account
	belongs_to :sc_segment
	before_create :record_new
	attr_accessor :new_item
  	
  	def to_label
    	'Accounts ScSegments'
  	end

	def new_item
		read_attribute(:new_item) rescue false
	end

	def record_new
		self.new_item = true
	end

end