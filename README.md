Rest whois server
=================

Rest whois server

Examlpe usege:

1) html request, GET:

    /v1/example.ee

2) json request, GET:

    /v1/example.ee.json

By default there will return only public info.
If you need full whois info, user needs to use Google ReCaptchia, example usage:

1) html for full whois info, GET: 
    
    /v1/test.ee?utf8=%E2%9C%93&g-recaptcha-response=03AHJ_VuvVgYnzxXAuf8rdHvTPQ5FZSHYZ...

2) json for full whois info, GET:

    /v1/example.ee.json?utf8=%E2%9C%93&g-recaptcha-response=03AHJ_VuvY4cI_oBaP1BtercOD...


Installation
------------

Rest whois is based on Rails 4

Manual demo install:

    git clone https://github.com/internetee/rest-whois/
    cd rest-whois
    rbenv local 2.2.7
    bundle install
    cp config/application-example.yml config/application.yml # and edit it
    cp config/database-example.yml config/database.yml # and edit it
    bundle exec rake db:setup # for production, please follow deployment howto

#### Installation of ruby 2.2.7 on rbenv

    rbenv install 2.2.7
    gem install bundle

Mac OS `brew` users might experience the [bug](https://github.com/rbenv/ruby-build/issues/1064) and require custom install command. Takes up to **10 minutes** to build:

    RUBY_CONFIGURE_OPTS=--with-readline-dir="$(brew --prefix readline)" rbenv install 2.2.7

Deployment
----------

    cd rest-whois
    mina pr setup
    edit shared/config/application.yml and shared/config/database.yml files

Add apache config file:

```
<VirtualHost *:80>
  ServerName your-rest-whois.ee

  PassengerRoot /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini
  PassengerRuby /home/registry/.rbenv/shims/ruby
  PassengerEnabled on
  PassengerMinInstances 10
  PassengerMaxPoolSize 10
  PassengerPoolIdleTime 0
  PassengerMaxRequests 1000

  RailsEnv production # or staging
  DocumentRoot /home/registry/rest-whois/current/public

  # Possible values include: debug, info, notice, warn, error, crit,
  LogLevel info
  ErrorLog /var/log/apache2/rest-whois.error.log
  CustomLog /var/log/apache2/rest-whois.access.log combined

  <Directory /home/registry/rest-whois/current/public>
    # for Apache older than version 2.4
    Allow from all

    # for Apache verison 2.4 or newer
    # Require all granted

    Options -MultiViews
  </Directory>
</VirtualHost>
```

Deploy from your machine:

    mina pr deploy

