# frozen_string_literal: true
require 'gir_ffi_test_helper'

describe GirFFI::Builders::FieldBuilder do
  let(:instance) { GirFFI::Builders::FieldBuilder.new field_info }

  describe 'for a field of type :gint8 with an offset' do
    let(:field_info) { get_field_introspection_data 'Regress', 'TestSimpleBoxedA', 'some_int8' }
    it 'creates the right getter method' do
      expected = <<-CODE.reset_indentation
        def some_int8
          _v1 = @struct.to_ptr + #{field_info.offset}
          _v2 = GirFFI::InOutPointer.new(:gint8, _v1)
          _v3 = _v2.get_int8(0)
          _v3
        end
      CODE
      instance.getter_def.must_equal expected
    end

    it 'creates the right setter method' do
      expected = <<-CODE.reset_indentation
        def some_int8= value
          _v1 = @struct.to_ptr + #{field_info.offset}
          _v2 = GirFFI::InOutPointer.new(:gint8, _v1)
          _v3 = value
          _v2.put_int8 0, _v3
        end
      CODE
      instance.setter_def.must_equal expected
    end
  end

  describe 'for a field of type :struct' do
    let(:field_info) { get_field_introspection_data 'Regress', 'TestBoxed', 'nested_a' }
    it 'creates the right getter method' do
      expected = <<-CODE.reset_indentation
        def nested_a
          _v1 = @struct.to_ptr + #{field_info.offset}
          _v2 = GirFFI::InOutPointer.new(Regress::TestSimpleBoxedA, _v1)
          _v3 = Regress::TestSimpleBoxedA.get_value_from_pointer(_v2, 0)
          _v4 = Regress::TestSimpleBoxedA.wrap(_v3)
          _v4
        end
      CODE
      instance.getter_def.must_equal expected
    end
  end

  describe 'for a field of type :enum' do
    let(:field_info) { get_field_introspection_data 'Regress', 'TestStructA', 'some_enum' }
    it 'creates the right getter method' do
      expected = <<-CODE.reset_indentation
        def some_enum
          _v1 = @struct.to_ptr + #{field_info.offset}
          _v2 = GirFFI::InOutPointer.new(Regress::TestEnum, _v1)
          _v3 = Regress::TestEnum.get_value_from_pointer(_v2, 0)
          _v3
        end
      CODE
      instance.getter_def.must_equal expected
    end
  end

  describe 'for an inline fixed-size array field' do
    let(:field_info) { get_field_introspection_data 'Regress', 'TestStructE', 'some_union' }
    it 'creates the right getter method' do
      expected = <<-CODE.reset_indentation
        def some_union
          _v1 = @struct.to_ptr + #{field_info.offset}
          _v2 = GirFFI::InOutPointer.new(:c, _v1)
          _v3 = GirFFI::SizedArray.get_value_from_pointer(_v2, 0)
          _v4 = GirFFI::SizedArray.wrap(Regress::TestStructE__some_union__union, 2, _v3)
          _v4
        end
      CODE
      instance.getter_def.must_equal expected
    end

    it 'creates the right setter method' do
      expected = <<-CODE.reset_indentation
        def some_union= value
          _v1 = @struct.to_ptr + #{field_info.offset}
          _v2 = GirFFI::InOutPointer.new(:c, _v1)
          GirFFI::ArgHelper.check_fixed_array_size 2, value, \"value\"
          _v3 = GirFFI::SizedArray.from(Regress::TestStructE__some_union__union, 2, value)
          GirFFI::SizedArray.copy_value_to_pointer(_v3, _v2)
        end
      CODE
      instance.setter_def.must_equal expected
    end
  end

  describe 'for a field of type :callback' do
    let(:field_info) { get_field_introspection_data 'GObject', 'TypeInfo', 'class_init' }
    it 'creates the right setter method' do
      expected = <<-CODE.reset_indentation
        def class_init= value
          _v1 = @struct.to_ptr + #{field_info.offset}
          _v2 = GirFFI::InOutPointer.new(GObject::ClassInitFunc, _v1)
          _v3 = GObject::ClassInitFunc.from(value)
          GObject::ClassInitFunc.copy_value_to_pointer(_v3, _v2)
        end
      CODE
      instance.setter_def.must_equal expected
    end
  end

  describe 'for a field with a related array length field' do
    let(:field_info) { get_field_introspection_data 'GObject', 'SignalQuery', 'param_types' }
    let(:n_params_field_info) { get_field_introspection_data 'GObject', 'SignalQuery', 'n_params' }

    it 'creates the right getter method' do
      skip if field_info.field_type.array_length < 0
      expected = <<-CODE.reset_indentation
        def param_types
          _v1 = @struct.to_ptr + #{n_params_field_info.offset}
          _v2 = GirFFI::InOutPointer.new(:guint32, _v1)
          _v3 = _v2.get_uint32(0)
          _v4 = @struct.to_ptr + #{field_info.offset}
          _v5 = GirFFI::InOutPointer.new([:pointer, :c], _v4)
          _v6 = _v5.get_pointer(0)
          _v7 = GirFFI::SizedArray.wrap(:GType, _v3, _v6)
          _v7
        end
      CODE
      instance.getter_def.must_equal expected
    end
  end
end
