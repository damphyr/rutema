#  Copyright (c) 2021 Markus Prasser. All rights reserved.

require_relative "../lib/rutema/core/framework"

require "test/unit"

module TestRutema
  ##
  # Verify functionality of Rutema::ErrorMessage
  class TestErrorMessage < Test::Unit::TestCase
    ##
    # Verify that an "empty" instance is stringified correctly
    def test_stringify_empty
      msg = Rutema::ErrorMessage.new({})
      assert_equal("ERROR - ", msg.to_s)
    end

    ##
    # Verify that an instance with data is stringified correctly
    def test_stringify
      msg = Rutema::ErrorMessage.new(
        :text => "a bad message"
      )
      assert_equal("ERROR - a bad message", msg.to_s)
      msg = Rutema::ErrorMessage.new(
        :test => "test_stringify", :text => "an even worse message"
      )
      assert_equal("ERROR - test_stringify an even worse message", msg.to_s)
    end
  end

  ##
  # Verify functionality of Rutema::Message
  class TestMessage < Test::Unit::TestCase
    ##
    # Verify successful default initialization if an empty hash is given
    def test_default_initialization
      before = Time.now
      msg = Rutema::Message.new({})
      after = Time.now
      assert_equal("", msg.test)
      assert_equal("", msg.text)
      assert(before < msg.timestamp && after > msg.timestamp)
    end

    ##
    # Verify successful initialization from a hash with data
    def test_initialization
      timestamp = Time.now
      msg = Rutema::Message.new(
        :test => "msg_test", :text => "some message", :timestamp => timestamp
      )
      assert_equal("msg_test", msg.test)
      assert_equal("some message", msg.text)
      assert_equal(timestamp, msg.timestamp)
    end

    ##
    # Verify that an "empty" instance is stringified correctly
    def test_stringify_empty
      msg = Rutema::Message.new({})
      assert_equal("", msg.to_s)
    end

    ##
    # Verify that an instance with data is stringified correctly
    def test_stringify
      msg = Rutema::Message.new(
        :text => "a message"
      )
      assert_equal("a message", msg.to_s)
      msg = Rutema::Message.new(
        :test => "test_stringify", :text => "some other message"
      )
      assert_equal("test_stringify some other message", msg.to_s)
    end
  end

  ##
  # Verify functionality of Rutema::Message
  class TestRunnerMessage < Test::Unit::TestCase
    ##
    # Verify successful default initialization if an empty hash is given
    def test_default_initialization
      before = Time.now
      msg = Rutema::RunnerMessage.new({})
      after = Time.now

      assert_equal("", msg.backtrace)
      assert_equal(0, msg.duration)
      assert_equal("", msg.err)
      assert_equal("", msg.is_special)
      assert_equal(1, msg.number)
      assert_equal("", msg.out)
      assert_equal(:none, msg.status)
      assert_equal("", msg.test)
      assert_equal("", msg.text)
      assert(before < msg.timestamp && after > msg.timestamp)
    end

    ##
    # Verify successful initialization from a hash with data
    def test_initialization
      timestamp = Time.now
      msg = Rutema::RunnerMessage.new(
        "backtrace" => "err_a\nerr_b", "duration" => 218, "err" => "the cause",
        "is_special" => "no, not at all", "number" => 3, "out" => "nothing",
        "status" => "mediocre", :test => "run_msg_ini", :text => "data message",
        :timestamp => timestamp
      )
      assert_equal("err_a\nerr_b", msg.backtrace)
      assert_equal(218, msg.duration)
      assert_equal("the cause", msg.err)
      assert_equal("no, not at all", msg.is_special)
      assert_equal(3, msg.number)
      assert_equal("nothing", msg.out)
      assert_equal("mediocre", msg.status)
      assert_equal("run_msg_ini", msg.test)
      assert_equal("data message", msg.text)
      assert_equal(timestamp, msg.timestamp)
    end

    ##
    # Verify correct functionality of Rutema::RunnerMessage#output
    def test_output
      msg = Rutema::RunnerMessage.new({})
      assert_equal("", msg.output)

      msg = Rutema::RunnerMessage.new(
        "err" => "oh oh, bad", "out" => "bla bla"
      )
      assert_equal("bla bla\noh oh, bad", msg.output)

      msg = Rutema::RunnerMessage.new(
        "backtrace" => "bad_a\nbad_b", "out" => "bla bla"
      )
      assert_equal("bla bla\n\nbad_a\nbad_b", msg.output)

      msg = Rutema::RunnerMessage.new(
        "backtrace" => "bad_a\nbad_b", "err" => "oh oh, bad", "out" => "bla bla"
      )
      assert_equal("bla bla\noh oh, bad\nbad_a\nbad_b", msg.output)
    end

    ##
    # Verify that an instance with data is stringified correctly
    def test_stringify
      msg = Rutema::RunnerMessage.new({})
      assert_match(/: \d{2}:\d{2}:\d{2} :/, msg.to_s)

      msg = Rutema::RunnerMessage.new(
        :test => "stringfctn_test"
      )
      assert_match(/stringfctn_test: \d{2}:\d{2}:\d{2} : Output\./, msg.to_s)

      msg = Rutema::RunnerMessage.new(
        :test => "stringfctn_test", :text => "some info"
      )
      assert_match(
        /stringfctn_test: \d{2}:\d{2}:\d{2} :some info\. Output\./, msg.to_s
      )

      msg = Rutema::RunnerMessage.new(
        "out" => "stdout", :test => "stringfctn_test", :text => "some info"
      )
      assert_match(
        /stringfctn_test: \d{2}:\d{2}:\d{2} :some info\. Output:\nstdout/, msg.to_s
      )
    end
  end
end
