#SiteCatalyst Refferal Traffic Reports
class ReplicaScReferralTraffic < ReplicaAccount
	belongs_to :sc_segment
	self.table_name = "sc_referral_traffic"

end