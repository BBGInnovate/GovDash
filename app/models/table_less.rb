class TableLess
  include ActiveModel::Model
  extend ActiveModel::Callbacks
  define_model_callbacks :save
  
  def initialize params
    params = Hash[params.map {|k,v| [k.to_s.gsub(' ','_').to_sym, v]}]
    super
  end
  
  # Just check validity, and if so, trigger callbacks.
  def save
    if valid?
      run_callbacks(:save) { true }
    else
      false
    end
  end
  
end

