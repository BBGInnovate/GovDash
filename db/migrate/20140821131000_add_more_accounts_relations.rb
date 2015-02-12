class AddMoreAccountsRelations < ActiveRecord::Migration
  def up
    Service.find_or_create_by name:  'Belarus'
    Language.find_or_create_by name: 'Belarusian'
    Language.find_or_create_by name: 'Azeri'
    Service.find_or_create_by name: 'Iraqi'
    Service.find_or_create_by name: 'Balkans'
    Language.find_or_create_by name: 'Croatian'
    ScSegment.find_or_create_by name: 'rus.azattyq.org', sc_id: '53f60cafe4b09c50798808e9'
    Service.find_or_create_by name: 'Kazakh'
    Service.find_or_create_by name: 'Uzbek'
    Language.find_or_create_by name: 'Uzbek'
  end
  
  def down
    # do nothing
  end
end
