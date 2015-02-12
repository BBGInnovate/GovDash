class ScSegment < ActiveRecord::Base
	has_and_belongs_to_many :accounts
	has_many :sc_referral_traffic
	#Represents a Sitecatalyst Segment

end
