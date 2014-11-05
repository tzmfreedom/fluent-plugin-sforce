# Fluent::Plugin::Sforce
[![Build Status](https://travis-ci.org/tzmfreedom/fluent-plugin-sforce.svg?branch=master)](https://travis-ci.org/tzmfreedom/fluent-plugin-sforce)  
Fluent Plugin for Salesforce.com

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-plugin-sforce'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-sforce

## Usage

```xml
<source>
  tag test.access
  type sforce
  username test@example.com
  password hogefuga
  query SELECT id, Body FROM FeedItem
  polling_interval 60
  # topic AllMessages
</source>
```

username : Salesforce Username for exporting data.  
password : Salesforce User's Password.  
query : SOQL Query.  
polling_interval : Query Interval Time.  
topic : PushTopic name to subscribe. 

## Contributing

1. Fork it ( https://github.com/tzmfreedom/fluent-plugin-sforce/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
