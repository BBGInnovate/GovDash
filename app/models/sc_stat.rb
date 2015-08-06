# require Rails.root.to_s + '/lib/read_stat_detail'

class ScStat < StatDetail
  # include ReadStatDetail

  def self.table_class
    ScReferralTraffic
  end
  def self.created_at
    'created_at'
  end
  def self.data_columns
  # in database select: select twitter_count AS twitter_count etc.
    {'twitter_count'=>'twitter_count',
     'facebook_count'=>'facebook_count'}
  end
  def self.select_option account_ids
    records = AccountsScSegment.where(["account_id in (?)", account_ids])
    segment_ids = records.map{|rec| rec.sc_segment_id}.uniq
    ["sc_segment_id in (?)", segment_ids]
  end

end
