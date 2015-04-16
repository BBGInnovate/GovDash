class AlterCodeCountries < ActiveRecord::Migration
  def change
    change_column(:countries, :code, :string, limit: 10)
  end
end
