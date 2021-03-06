# require Rails.root.to_s + '/lib/read_stat_detail'

class ScStat < StatDetail
  # include ReadStatDetail

  def self.table_class
    REPLICA ? ReplicaScReferralTraffic : ScReferralTraffic
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
    @segment_ids ||= AccountsScSegment.where(["account_id in (?)", account_ids]).
       pluck(:sc_segment_id).uniq
    ["sc_segment_id in (?)", @segment_ids]
  end

  def select_summary_sql
    arr = ["sc_segment_id"]
    self.class.data_columns.each_pair do | col, _as |
      arr << "COALESCE(sum(#{col}),0) as #{_as}" 
    end
    arr.join(',')
  end
  
end
