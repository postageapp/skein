require_relative '../helper'

class TestSkeinRPCRequest < Test::Unit::TestCase
  def test_default
    request = Skein::RPC::Request.new

    assert request.id
    assert request.id.match(/\A\h{8}\-\h{4}\-\h{4}\-\h{4}\-\h{12}\z/)

    assert_equal nil, request.method
    assert_equal nil, request.params
  end

  def test_with_invalid_method_name
    request = Skein::RPC::Request.new(
      method: 'invalid name',
      id: 'aa8304bd-5c4a-4b77-a1bf-87f90d59b3af'
    )

  rescue Skein::RPC::InvalidMethod => e
    assert e

    assert e.request.is_a?(Skein::RPC::Request)
    assert_equal 'aa8304bd-5c4a-4b77-a1bf-87f90d59b3af', e.to_error.id
  else
    fail
  end

  def test_with_no_method_name
    request = Skein::RPC::Request.new(
      method: nil,
      id: 'aa8304bd-5c4a-4b77-a1bf-87f90d59b3af'
    )
  end

  def test_with_single_param
    request = Skein::RPC::Request.new(
      method: 'single_param',
      params: 'single'
    )

    assert_equal %w[ single ], request.params
  end

  def test_from_json_string
    raw = {
      method: 'test_method',
      params: nil,
      id: 'e0b6cffa-8040-4c44-bc11-7fc3d8f4662c'
    }

    json = JSON.dump(raw)

    request = Skein::RPC::Request.new(json)

    assert_equal 'test_method', request.method
    assert_equal nil, request.params
    assert_equal 'e0b6cffa-8040-4c44-bc11-7fc3d8f4662c', request.id

    assert_equal raw, request.to_h
  end

  def test_from_hash
    raw = {
      method: 'test_method',
      params: nil,
      id: 'e0b6cffa-8040-4c44-bc11-7fc3d8f4662c'
    }

    request = Skein::RPC::Request.new(raw)

    assert_equal 'test_method', request.method
    assert_equal nil, request.params
    assert_equal 'e0b6cffa-8040-4c44-bc11-7fc3d8f4662c', request.id

    assert_equal raw, request.to_h
  end

  def test_to_response_result
    request = Skein::RPC::Request.new(
      method: 'test_method',
      params: 'test',
      id: 'd8b625f1-5e0b-4bcf-bf6e-569e9edc634d'
    )

    response = request.response(
      result: %w[ result ]
    )

    assert_equal request.id, response.id
    assert_equal %w[ result ], response.result
  end
end
