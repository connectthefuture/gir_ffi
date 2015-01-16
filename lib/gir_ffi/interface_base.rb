require 'gir_ffi/registered_type_base'

module GirFFI
  # Base module for modules representing GLib interfaces.
  module InterfaceBase
    include RegisteredTypeBase

    def setup_instance_method name
      gir_ffi_builder.setup_instance_method name
    end

    def wrap ptr
      ptr.to_object
    end

    # @deprecated Use #to_ffi_type instead. Will be removed in 0.8.0.
    def to_ffitype
      to_ffi_type
    end

    def to_ffi_type
      :pointer
    end
  end
end
