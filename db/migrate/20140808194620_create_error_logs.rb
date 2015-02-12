class CreateErrorLogs < ActiveRecord::Migration
  def up
    unless ActiveRecord::Base.connection.table_exists? 'error_logs'
    create_table :error_logs do |t|
      t.string :message, :limit=>1024
      t.string :subject, :default=>""
      t.integer :severity, :limit=>1  # 0 - 255
      t.boolean :email_sent 
      t.timestamps
    end
    end
  end
  def down 
    drop_table :error_logs
  end
end
