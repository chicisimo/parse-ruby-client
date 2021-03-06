require 'helper'

class TestPush < ParseTestCase
  def test_save_without_where
    data = { foo: 'bar',
             alert: 'message' }
    pf_push = Parse::Push.new(data, 'some_chan', @client)
    pf_push.type = 'ios'

    # query = Parse::Query.new(Parse::Protocol::CLASS_INSTALLATION, client = @client).eq('deviceToken', 'baz')

    Parse::Client.any_instance.expects(:request).with do |_uri, method, body, q|
      hash = JSON.parse(body)
      assert_equal :post, method
      assert has_entries('channel' => 'some_chan').matches?([hash])
      assert has_entries('foo' => 'bar', 'alert' => 'message').matches?([hash['data']])
      assert_nil q
      true
    end.returns({}.to_json)

    pf_push.save
  end

  def test_save_with_channels_removes_channel
    data = { foo: 'bar', alert: 'message' }
    pf_push = Parse::Push.new(data, 'some_chan', @client)
    pf_push.type = 'ios'

    query = Parse::Query.new(Parse::Protocol::CLASS_INSTALLATION, @client).eq('deviceToken', 'baz')
    pf_push.where = query.where

    pf_push.channels = %w(foo bar)

    Parse::Client.any_instance.expects(:request).with do |_uri, _method, body, _query|
      hash = JSON.parse(body)
      refute has_entries('channel' => 'some_chan').matches?([hash])
      assert has_entries('deviceToken' => 'baz', 'deviceType' => 'ios').matches?([hash['where']])
      true
    end.returns({}.to_json)

    pf_push.save
  end
end
