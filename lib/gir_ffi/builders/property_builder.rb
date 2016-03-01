# frozen_string_literal: true
require 'gir_ffi/builders/property_return_value_builder'

module GirFFI
  module Builders
    # Creates property getter and setter code for a given IPropertyInfo.
    class PropertyBuilder
      def initialize(property_info)
        @info = property_info
      end

      def build
        setup_getter
        setup_setter if setting_allowed
      end

      def setup_getter
        container_class.class_eval getter_def unless container_defines_getter_method?
      end

      def container_defines_getter_method?
        container_info.find_instance_method getter_name
      end

      def setup_setter
        container_class.class_eval setter_def
      end

      def getter_def
        converting_getter_def
      end

      # TODO: Fix argument builders so converting_setter_def can always be used.
      def setter_def
        case type_info.flattened_tag
        when :glist, :ghash, :strv
          converting_setter_def
        else
          simple_setter_def
        end
      end

      private

      # TODO: Use a builder like MarshallingMethodBuilder
      def converting_getter_def
        capture = getter_builder.capture_variable_name
        <<-CODE.reset_indentation
        def #{getter_name}
          #{capture} = get_property("#{property_name}")
          #{getter_builder.post_conversion.join("\n")}
          #{getter_builder.return_value_name}
        end
        CODE
      end

      def getter_builder
        @getter_builder ||=
          PropertyReturnValueBuilder.new(VariableNameGenerator.new,
                                         argument_info)
      end

      def converting_setter_def
        <<-CODE.reset_indentation
        def #{setter_name} value
          #{setter_builder.pre_conversion.join("\n")}
          set_property("#{property_name}", #{setter_builder.call_argument_name})
        end
        CODE
      end

      def simple_setter_def
        <<-CODE.reset_indentation
        def #{setter_name} value
          set_property("#{property_name}", value)
        end
        CODE
      end

      def setter_builder
        @setter_builder ||= ArgumentBuilder.new(VariableNameGenerator.new,
                                                argument_info)
      end

      def property_name
        @info.name
      end

      def getter_name
        @info.getter_name
      end

      def setter_name
        @info.setter_name
      end

      def type_info
        @type_info ||= @info.property_type
      end

      def argument_info
        @argument_info ||= FieldArgumentInfo.new('value', type_info)
      end

      def container_class
        @container_class ||= container_module.const_get(container_info.safe_name)
      end

      def container_module
        @container_module ||= Object.const_get(container_info.safe_namespace)
      end

      def container_info
        @container_info ||= @info.container
      end

      def setting_allowed
        @info.writeable? && !@info.construct_only?
      end
    end
  end
end
