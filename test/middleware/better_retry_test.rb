# -*- encoding : utf-8 -*-
require 'helper'

module Middleware
  class BetterRetryTest < Faraday::TestCase
    def setup
      @times_called = 0
    end

    def conn(retry_options = {})
      Faraday.new do |b|
        b.use Faraday::BetterRetry, retry_options
        b.adapter :test do |stub|
          stub.post('/unstable') do
            @times_called += 1
            @explode.call @times_called
          end
        end
      end
    end

    def test_unhandled_error
      @explode = ->(_n) { fail 'boom!' }
      assert_raises(RuntimeError) { conn.post('/unstable') }
      assert_equal 1, @times_called
    end

    def test_handled_error
      @explode = ->(_n) { fail Errno::ETIMEDOUT }
      assert_raises(Errno::ETIMEDOUT) { conn.post('/unstable') }
      assert_equal 3, @times_called
    end

    def test_new_max_retries
      @explode = ->(_n) { fail Errno::ETIMEDOUT }
      assert_raises(Errno::ETIMEDOUT) { conn(max: 3).post('/unstable') }
      assert_equal 4, @times_called
    end

    def test_interval
      @explode = ->(_n) { fail Errno::ETIMEDOUT }
      started  = Time.now
      assert_raises(Errno::ETIMEDOUT) do
        conn(max: 2, interval: 0.1).post('/unstable')
      end
      assert_in_delta 0.2, Time.now - started, 0.03
    end

    def test_custom_exceptions
      @explode = ->(_n) { fail 'boom!' }
      assert_raises(RuntimeError) do
        conn(exceptions: StandardError).post('/unstable')
      end
      assert_equal 3, @times_called
    end
  end
end
