require 'gir_ffi_test_helper'

describe GirFFI::Builders::SignalClosureBuilder do
  let(:builder) { GirFFI::Builders::SignalClosureBuilder.new signal_info }

  describe "#build_class" do
    let(:signal_info) {
      get_signal_introspection_data "Regress", "TestObj", "test" }

    it "builds a descendant of RubyClosure" do
      klass = builder.build_class
      klass.ancestors.must_include GObject::RubyClosure
    end
  end

  describe "#marshaller_definition" do
    describe "for a signal with no arguments or return value" do
      let(:signal_info) {
        get_signal_introspection_data "Regress", "TestObj", "test" }

      it "returns a valid marshaller converting only the receiver" do
        expected = <<-CODE.reset_indentation
        def self.marshaller(closure, return_value, param_values, _invocation_hint, _marshal_data)
          _instance, _ = param_values.map(&:get_value_plain)
          _v1 = _instance
          wrap(closure.to_ptr).invoke_block(_v1)
        end
        CODE

        builder.marshaller_definition.must_equal expected
      end
    end

    describe "for a signal with an argument and a return value" do
      let(:signal_info) {
        get_signal_introspection_data "Regress", "TestObj", "sig-with-int64-prop" }

      it "returns a valid mapping method" do
        skip unless signal_info

        expected = <<-CODE.reset_indentation
        def self.marshaller(closure, return_value, param_values, _invocation_hint, _marshal_data)
          _instance, i = param_values.map(&:get_value_plain)
          _v1 = _instance
          _v2 = i
          _v3 = wrap(closure.to_ptr).invoke_block(_v1, _v2)
          return_value.set_value _v3
        end
        CODE

        builder.marshaller_definition.must_equal expected
      end
    end

    describe "for a signal with an enum argument" do
      let(:signal_info) {
        get_signal_introspection_data "Gio", "MountOperation", "reply" }

      it "returns a valid mapping method" do
        expected = <<-CODE.reset_indentation
        def self.marshaller(closure, return_value, param_values, _invocation_hint, _marshal_data)
          _instance, result = param_values.map(&:get_value_plain)
          _v1 = _instance
          _v2 = result
          wrap(closure.to_ptr).invoke_block(_v1, _v2)
        end
        CODE

        builder.marshaller_definition.must_equal expected
      end
    end

    describe "for a signal with a array plus length arguments" do
      let(:signal_info) {
        get_signal_introspection_data "Regress", "TestObj", "sig-with-array-len-prop" }

      it "returns a valid mapping method" do
        skip unless signal_info

        expected = <<-CODE.reset_indentation
        def self.marshaller(closure, return_value, param_values, _invocation_hint, _marshal_data)
          _instance, arr, len = param_values.map(&:get_value_plain)
          _v1 = _instance
          _v2 = len
          _v3 = GirFFI::SizedArray.wrap(:guint32, _v2, arr)
          wrap(closure.to_ptr).invoke_block(_v1, _v3)
        end
        CODE

        builder.marshaller_definition.must_equal expected
      end
    end

    describe "for a signal with a struct argument" do
      let(:signal_info) {
        get_signal_introspection_data "Regress", "TestObj", "test-with-static-scope-arg" }

      it "returns a valid mapping method" do
        skip unless signal_info

        expected = <<-CODE.reset_indentation
        def self.marshaller(closure, return_value, param_values, _invocation_hint, _marshal_data)
          _instance, object = param_values.map(&:get_value_plain)
          _v1 = _instance
          _v2 = Regress::TestSimpleBoxedA.wrap(object)
          wrap(closure.to_ptr).invoke_block(_v1, _v2)
        end
        CODE

        builder.marshaller_definition.must_equal expected
      end
    end

    describe "for a signal returning an array of integers" do
      let(:signal_info) {
        get_signal_introspection_data "Regress", "TestObj", "sig-with-intarray-ret" }

      it "returns a valid mapping method" do
        skip unless signal_info

        expected = <<-CODE.reset_indentation
        def self.marshaller(closure, return_value, param_values, _invocation_hint, _marshal_data)
          _instance, i = param_values.map(&:get_value_plain)
          _v1 = _instance
          _v2 = i
          _v3 = wrap(closure.to_ptr).invoke_block(_v1, _v2)
          _v4 = GLib::Array.from(:gint32, _v3)
          return_value.set_value _v4
        end
        CODE

        builder.marshaller_definition.must_equal expected
      end
    end
  end
end
