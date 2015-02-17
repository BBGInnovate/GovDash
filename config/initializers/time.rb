class Time
  def change_to(length=1.month, direction="ago")
    direction.match /(ago)|(after)/
    if $1 == 'ago'
      self - length
    else
      self + length
    end
  end
=begin
def change_to(format="1.month.ago")
    if format.match /^(\d+)\.([a-z]+)\.([a-z]+)$/
      num = $1.to_i
      period = $2
      direction = $3
      if direction == 'ago'
        if period.match /month/i
          self.change month: (self.month-num)
        elsif period.match /day/i
          self.change day: (self.day-num)
        elsif period.match /week/i
          self.change day: (self.day-num*7)
        end
      else
        raise "Format 1.months.ago | 2.days.ago"
      end
    else
      raise "Format 1.months.ago | 2.days.ago"
    end
  end
=end
end
