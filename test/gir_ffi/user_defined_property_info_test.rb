# frozen_string_literal: true
require 'gir_ffi_test_helper'
require 'gir_ffi/user_defined_property_info'

describe GirFFI::UserDefinedPropertyInfo do
  describe '#param_spec' do
    it 'returns the passed in parameter specification' do
      info = GirFFI::UserDefinedPropertyInfo.new :some_param_spec
      info.param_spec.must_equal :some_param_spec
    end
  end

  describe '#name' do
    it 'returns the name retrieved from the parameter specification' do
      expect(param_spec = Object.new).to receive(:get_name).and_return :property_name
      info = GirFFI::UserDefinedPropertyInfo.new param_spec
      info.name.must_equal :property_name
    end
  end
end
