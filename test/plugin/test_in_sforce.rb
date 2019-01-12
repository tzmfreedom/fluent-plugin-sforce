require 'helper'

class SforceInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    type sforce
    username test@example.com
    password hogefuga
    tag test.access
    query SELECT id, Name FROM Account
    polling_interval 60
  ]

  def test_configure
    d = create_driver

    assert_equal 'test@example.com', d.instance.username
    assert_equal 'hogefuga', d.instance.password
    assert_equal 'test.access', d.instance.tag
    assert_equal 'SELECT id, Name FROM Account', d.instance.query
    assert_equal 60, d.instance.polling_interval
  end

  # TODO
  def test_emit; end

  private

  def create_driver(conf = CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::Plugin::SforceInput).configure(conf)
  end
end