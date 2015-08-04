require 'ostruct'
class Api::V2::SubrolesController < Api::V2::BaseController
  before_filter :authenticate_user!

  def index
    arr = []
    Subrole.all.each do | subrole |
      arr << subrole.attributes
    end
    pretty_respond arr
  end
   
  private

end