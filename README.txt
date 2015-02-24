---- Installation Instruction

All configurations below are overriden by OpsWorks
to provide real auth parameters

application.rb database.yml email.yml facebook.yml
s3.yml sitecatalyst.yml twitter.yml twitter.yml
rabbit.yml

1. MySQL database $db_name installation
  $db_name=govdash_app
  
  After deploy source code to target, 
  login to MySQL client and run
  # replace variables by the real values
  # dump radd_production 
  mysqldump -u$db_user -p  -h$db_host radd_production > dash.sql
  # load to dash_production
  mysql -u$db_user -p -h$db_host -D$db_name < dash.sql
  
  In MySQL client, execute query to create table app_token
  This table is to replace api_tokens
  
  CREATE TABLE `app_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `platform` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `canvas_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `api_user_email` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  `client_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `client_secret` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_access_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `page_access_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

2. run `rails c production`
  Copy and paste following code in Rails console:
  FacebookAccount.all.each do |fb|
    tn = fb.api_tokens[ fb.id % 2]
    if tn.page_access_token
      email = tn.api_user_email
      fb.update_attribute :contact,email
      AppToken.find_or_create_by platform: 'Facebook', 
        canvas_url: tn.canvas_url,
        api_user_email: tn.api_user_email,
        user_access_token: tn.user_access_token,
        page_access_token: tn.page_access_token
    end
  end

3. In MySQL client
  # note, find corresponding client_secret from smdata.bbg.gov
  # facebook.yml and replace '?' with the real values.
  update app_tokens set client_id='1485668908334414', client_secret='?' where api_user_email='ads@bbg.gov';
  update app_tokens set client_id='518623351606222', client_secret='?' where api_user_email='odditect@bbg.gov';
  update app_tokens set api_user_email='oddidev@bbg.gov',client_id='?', client_secret='?' where canvas_url='smdata.bbg.gov';

4. After testing the Facebook account retrieve functions successfully,
   In MySQL client, remove columns 
    ALTER TABLE accounts DROP COLUMN user_access_token;
    ALTER TABLE accounts DROP COLUMN page_access_token;
   
    -- And drop table api_tokens, note 
    -- api_tokens is replaced by app_tokens
    DROP TABLE api_tokens;

5. Add custom cookbook to override OpsWorks default Apache, Passenger
   configurations and set up cron jobs.
   Repository:
   bitbucket.org/****/cookbooks.git
   Branch: uberdashboard
   
6. Custom JSON applied to GovDash Stack settings
   {
  "deploy": {
       "socialdash_app": {
         "database": {
              "redshift_host": "facebook-results.*****.amazonaws.com",
              "redshift_port": "5439",
              "redshift_pool": "10",
              "redshift_timeout": "5000",
              "redshift_database": "****",
              "redshift_username": "****",
              "redshift_password": "****"
         },
         "facebook": {
              "client_id": "****",
              "client_secret": "****"
         },
         "symlink_before_migrate": {
            "config/email.yml": "config/email.yml",
            "config/facebook.yml": "config/facebook.yml",
            "config/rabbit.yml": "config/rabbit.yml",
            "config/s3.yml": "config/s3.yml",
            "config/sitecatalyst.yml": "config/sitecatalyst.yml",
            "config/twitter.yml": "config/twitter.yml"
         }
      }
   }
}
7. Add to <rails root>/deploy/after_restart.rb
   to run bin/delayed_job restart
   
8. For cron jobs
   1. Add to custom cookbook directory
      socialdash/recipes/cronjob.rb
   2. In GovDash Stack, Run Command "Update Custom Cookbook"
      and run "Execute Recipes", add to "Recipes to execute" with
      socialdash::crontab
   3. Click "govdash-24-7" instance
   4. Click "Execute Recipes"


