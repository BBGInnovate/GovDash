class DelayedJob < ActiveRecord::Base
  def self.active
    now = Time.zone.now.to_s(:db)
    data = where("locked_by is not null").to_a
    data.each do |a|
      h = a.handler.gsub("\n", ' ')
      h.match /object_name: (\w+)/
      puts "  Object Name: #{$1} run_at: #{a.run_at.to_s(:db)} Now: #{now}"
    end
  end
  
  def self.to_run
    now = Time.zone.now.to_s(:db)
    data = where("locked_by is null").to_a
    data.each do |a|
      h = a.handler.gsub("\n", ' ')
      h.match /object_name: (\w+)/
      puts "  Object Name: #{$1} run_at: #{a.run_at.to_s(:db)} Now: #{now}"
    end
  end
  
end
