---- Installation Instruction

All configurations below are overriden by OpsWorks
to provide real auth parameters

database.yml 
email.yml
facebook.yml
rabbit.yml
s3.yml 
sitecatalyst.yml 
twitter.yml
youtube.yml

Setup Devise and OmniAuth for OAuth2 Authentication to Google
  Create a Google Development Project
    with callback uri:
      http://localhost:3000/users/auth/google_oauth2/callback
    
  Login to https://console.developers.google.com/apis/credentials/
    choose a OAuth 2.0 client IDs and click "Download JSON".
    save the json file to
    config/client_secrets.json
    
  Create database table google_access_tokens to store token and refresh_token
  
  Modify app/models/user.rb
    add to devise :omniauthable, :omniauth_providers => [:google_oauth2]
  
  Add to config/initializers/devise.rb
    config.omniauth_path_prefix = "/users/auth"
    config.omniauth :google_oauth2, client_id, client_secret
    
 Modify config/initializers/youtube.rb, add
    config.client_id 
    config.client_secret
  
  Modify confing/routes.rb
    change devise_for :users
    to
    devise_for :users, :controllers => { :omniauth_callbacks => "callbacks" }

  Create controller
    app/controllers/callbacks_controller.rb with method "google_oauth2":
    
  Create config/initializers/omniauth.rb, add lines below:
  
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2, YoutubeConf[:client_id], YoutubeConf[:client_secret],
    {
      :name => "google",
      :scope => YoutubeConf[:scopes],
      :prompt => "select_account",
      :image_aspect_ratio => "square",
      :image_size => 50,
      :access_type => 'offline'
    }
  end
  
  Finally 
    Clear cache for your default browser and
    get to page http://localhost:3000/users/auth/google_oauth2
    This will store the access token to google_access_tokens table
    
    Create a cron run every 50 minutes (the token expires in 0 minutes)
    Run GoogleAccessToken.last.refresh_token_if_expired
    
1. MySQL database govdash_app setup
  There are two methods to set up the database.
  
  1. Dump database with full contents from radd_production
     database in AWS OpsWorks SocialDashboard stack.
     Use this method if you want to copy all Facebook and Twitter
     accounts data over. To do this, follow the steps below:
     1.1 Dump database, run command
         # replace the variables
         mysqldump -u$db_user -p -h$db_host radd_production > dash.sql
     1.2 Load dash.sql to govdash_app
         # replace the variables
         mysql -u$db_user -p -h$db_host -D$db_name < dash.sql
     1.3 Connect to govdash_app database
         Execute query to create table app_token
         Note: this table is to replace api_tokens
  
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

     1.4 If you want to get FAcebook InSights data,
         follow the steps below:
         1.4.1 Open Rails Console by command `rails c production`
         1.4.2 Migrate page_access_token from accounts table to
               app_tokens table:
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
         1.4.3 Update app_tokens set client_id and secret
               Note: find corresponding client_secret from smdata.bbg.gov
               facebook.yml and replace '?' with the real values.
               update app_tokens set client_id='1485668908334414', client_secret='?' where api_user_email='ads@bbg.gov';
               update app_tokens set client_id='518623351606222', client_secret='?' where api_user_email='odditect@bbg.gov';
               update app_tokens set api_user_email='oddidev@bbg.gov',client_id='?', client_secret='?' where canvas_url='smdata.bbg.gov';
         1.4.4 Optional remove columns from accounts table, after 
               testing the Facebook account retrieve functions 
               successfully
   
               ALTER TABLE accounts DROP COLUMN user_access_token;
               ALTER TABLE accounts DROP COLUMN page_access_token;
               DROP TABLE api_tokens;
               
  2. Use db/schema.rb in this project
     2.1 In Rail Root, run
         rake db:schema:load

3. If you want to get Facebook InSights data and require page_access_token
   for accounts not covered in item 1.4
   Go to page <govdash-loadbalancer>/facebooks/index
   and follow the instrunctions there.

2. Create custom cookbook and host in bitbucket.org/****/cookbooks.git
   Strucure of cookbooks:
     apache2/attributes/customize.rb  #=> override Apache conf parameters
     passenger_apache2/attributes/customize.rb #=> override Passenger parameters
     rails/attributes/customize.rb #=> override database connection pool size
     rails/recipes/myconfigure.rb #=> create conf files in shared/config/
     rails/templates/default/ #=> templates for all required config files
     socialdash/recipes/cronjob.rb
     
3. Add custom cookbook to OpsWorks stack

   In GovDash Stack Settings
   Use custom Chef cookbooks: Yes
   Repository URL: bitbucket.org/****/cookbooks.git
   Branch: uberdashboard
   Custom JSON:
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
         "youtube": {
              "delayed_jobs": 5
         }
       }
     }
   }

4. Layer Rails App Server Recipes
     Repository URL: git@bitbucket.org:****/cookbooks.git
     Configure: socialdash::cronjob rails::myconfigure 
     DeployL    socialdash::cronjob 

     OS Packages:  rabbitmq-server

5. Start OpsWorks GovDash Stack instance
   When the instance is up, make sure:
   5.1 User "deploy" cronjobs are created for Facebook, Twitter, Youtube
       sitecatalyst
   5.2 <rails-app>/current/config/ symbalic links are created
   5.3 delayed_job daemon is running
   
6. If you want to use AWS Redshift Database
   6.1 Run the following PostgreSQL commands

create table fb_pages (
  original_id integer,
  account_id integer,
  object_name varchar(40) ,
  total_likes integer,
  total_comments integer,
  total_shares integer,
  total_talking_about integer,
  likes integer,
  comments integer,
  shares integer,
  posts integer,
  replies_to_comment integer,
  fan_adds_day integer,
  story_adds_day integer,
  story_adds_by_story_type_day varchar(255),
  consumptions_day integer,
  consumptions_by_consumption_type_day varchar(255),
  stories_week integer,
  stories_day_28 integer,
  stories_by_story_type_week varchar(255),
  post_created_time timestamp,
  created_at timestamp,
  updated_at timestamp,
  primary key(original_id)
)
distkey(account_id)
sortkey(original_id, post_created_time, account_id)


CREATE TABLE fb_posts (
  original_id integer,
  account_id integer NULL,
  post_id varchar(40) UNIQUE,
  likes integer NULL,
  comments integer NULL,
  shares integer NULL,
  post_type varchar(20) NULL,
  replies_to_comment integer NULL,
  post_created_time timestamp NULL,
  created_at timestamp NULL,
  updated_at timestamp NULL,
  primary key(original_id)
)
distkey(account_id)
sortkey(account_id, post_created_time)

CREATE TABLE tw_timelines (
  original_id integer NOT NULL,
  account_id integer NULL,
  object_name varchar(40) NULL,
  total_tweets integer NULL,
  total_favorites integer NULL,
  total_followers integer NULL,
  tweets integer NULL,
  favorites integer NULL,
  followers integer NULL,
  retweets integer NULL,
  mentions integer NULL,
  tweet_created_at timestamp NULL,
  created_at timestamp NULL,
  updated_at timestamp NULL,
  PRIMARY KEY (original_id)
)
distkey(account_id)
sortkey(original_id, tweet_created_at, account_id)

CREATE TABLE tw_tweets (
  original_id integer NOT NULL,
  account_id integer NULL,
  tweet_id bigint NULL,
  retweets integer NULL,
  favorites integer NULL,
  mentions integer NULL,
  tweet_created_at timestamp NULL,
  created_at timestamp NULL,
  updated_at timestamp NULL,
  PRIMARY KEY (original_id)
)
distkey(account_id)
sortkey(original_id, tweet_created_at, tweet_id)

CREATE TABLE yt_channels (
   original_id integer NOT NULL,
   account_id integer NOT NULL,
   channel_id varchar(255),
   views integer,
   comments integer,
   videos integer,
   subscribers integer,
   video_subscribers integer,
   video_comments integer,
   video_favorites integer,
   video_likes integer,
   video_views integer,
   published_at timestamp,
   created_at timestamp,
   updated_at timestamp,
  PRIMARY KEY (original_id)
)
distkey(account_id)
sortkey(original_id, channel_id, published_at)


CREATE TABLE yt_videos (
  original_id integer NOT NULL,
  account_id integer NOT NULL,
  video_id varchar(40),
  comments integer,
  favorites integer,
  likes integer,
  views integer,
  published_at timestamp,
  created_at timestamp,
  updated_at timestamp,
  PRIMARY KEY (original_id)
)
distkey(video_id)
sortkey(original_id, account_id, published_at)

7. References:
   Chef Resources:
   http://support.rightscale.com/12-Guides/Chef_Cookbooks_Developer_Guide/04-Developer/06-Development_Resources/Chef_Resources
   https://docs.chef.io/resource_examples.html
   
   Use Social Media Registry
   http://www.usa.gov/About/developer-resources/social-media-registry.shtml
   https://github.com/measuredvoice/estuary/tree/master/lib/services
   
8. Useful command line tools for Rails developer
   Launch PostgreSQL (PSQL) client:
    /Applications/Postgres.app/Contents/Versions/9.4/bin/psql -h 127.0.0.1 -U oddidev -p 5439 -d pages
   Drop PSQL database:
    /Applications/Postgres.app/Contents/Versions/9.4/bin/dropdb -h 127.0.0.1 -p 5439 -U oddidev -i pages
   Create PSQL database:
    /Applications/Postgres.app/Contents/Versions/9.4/bin/createdb -h 127.0.0.1 -p 5439 -U oddidev -E UTF8 -e pages    
   Kill PSQL process of id 1234:
    select pg_cancel_backend(1234);
    select pg_terminate_backend(1234);
   Find PSQL running processes:
    SELECT * FROM pg_stat_activity WHERE datname = 'yt_channels';

   # tail OpsWorks log
   sudo /usr/sbin/opsworks-agent-cli show_log
