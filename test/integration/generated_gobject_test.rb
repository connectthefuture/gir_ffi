require 'gir_ffi_test_helper'

GirFFI.setup :Regress

describe GObject do
  describe '.type_interfaces' do
    it 'works, showing that returning an array of GType works' do
      klass = GObject::TypeModule
      ifcs = GObject.type_interfaces klass.gtype
      assert_equal 1, ifcs.size
    end
  end

  describe '.signal_set_va_marshaller' do
    it 'can be set up' do
      result = GObject.setup_method 'signal_set_va_marshaller'
      result.must_equal true
    end
  end

  describe GObject::TypeInfo do
    let(:instance) { GObject::TypeInfo.new }
    it 'has a working field setter for class_init' do
      instance.class_init = proc do |_object_class, _data|
      end
    end

    it 'has a working field getter for class_init' do
      instance.class_init.must_be_nil
      instance.class_init = proc do |_object_class, _data|
      end
      result = instance.class_init
      result.wont_be_nil
      result.must_be_instance_of FFI::Function
    end
  end

  describe GObject::TypePlugin do
    it 'is implemented as a module' do
      mod = GObject::TypePlugin
      assert_instance_of Module, mod
      refute_instance_of Class, mod
    end
  end

  describe GObject::TypeModule do
    it 'has the GObject::TypePlugin module as an ancestor' do
      klass = GObject::TypeModule
      assert_includes klass.ancestors, GObject::TypePlugin
    end
  end

  describe GObject::ValueArray do
    it 'uses the constructor provided by GObject' do
      instance = GObject::ValueArray.new 16
      instance.n_prealloced.must_equal 16
      instance.n_values.must_equal 0
    end
  end

  describe GObject::SignalQuery do
    it 'works' do
      GObject::SignalQuery.new
      pass
    end

    it 'uses the n_params field for the length of param_types' do
      field_info = get_field_introspection_data 'GObject', 'SignalQuery', 'param_types'
      skip if field_info.field_type.array_length < 0
      gtype = GObject::Object.gtype
      signals = GObject.signal_list_ids gtype
      signal_query = GObject.signal_query signals.first
      signal_query.n_params.must_equal 1
      signal_query.param_types.size.must_equal 1
    end
  end

  describe GObject::Binding do
    it 'is created with GObject::Object#bind_property' do
      source = Regress::TestObj.constructor
      target = Regress::TestObj.constructor
      binding = source.bind_property 'double', target, 'double', default: true
      binding.must_be_kind_of GObject::Binding
    end

    describe 'an instance' do
      let(:source) { Regress::TestObj.constructor }
      let(:target) { Regress::TestObj.constructor }
      let(:binding) { source.bind_property 'double', target, 'double', default: true }

      it 'can read the property "target-property" with #get_property' do
        binding.get_property('target-property').must_equal 'double'
      end

      it 'can read the property "target-property" with #target_property' do
        binding.target_property.must_equal 'double'
      end

      it 'cannot write the property "target-property" with #target_property=' do
        proc { binding.target_property = 'foo' }.must_raise NoMethodError
      end
    end
  end
end
