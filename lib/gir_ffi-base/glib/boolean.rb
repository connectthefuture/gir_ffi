require 'ffi'

module GLib
  # Implementation of gboolean
  class Boolean
    extend FFI::DataConverter
    native_type :int #FFI::Type::INT

    def self.from_native value, context
      value != 0 ? true : false
    end

    def self.to_native value, context
      value ? 1 : 0
    end

    def self.size
      FFI.type_size self
    end

    def self.copy_value_to_pointer value, pointer
      pointer.put_int 0, to_native(value, nil)
    end

    def self.get_value_from_pointer pointer
      from_native pointer.get_int(0), nil
    end
  end
end
