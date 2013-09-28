require 'gir_ffi/builder_helper'

module GirFFI

  # Base class for type builders.
  class BaseTypeBuilder
    include BuilderHelper

    def initialize info
      @info = info
      @namespace = @info.namespace
      @classname = @info.safe_name
    end

    def build_class
      unless defined? @klass
        instantiate_class
      end
      @klass
    end

    attr_reader :info

    private

    def namespace_module
      @namespace_module ||= Builder.build_module @namespace
    end

    def lib
      @lib ||= namespace_module.const_get :Lib
    end

    def setup_constants
      @klass.const_set :GIR_INFO, info
      @klass.const_set :GIR_FFI_BUILDER, self
    end

    def already_set_up
      const_defined_for @klass, :GIR_FFI_BUILDER
    end

    def gir
      @gir ||= GObjectIntrospection::IRepository.default
    end
  end
end