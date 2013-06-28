module GirFFI
  module EnumBase
    def [](arg)
      self::Enum[arg]
    end

    def setup_and_call method, *arguments, &block
      result = setup_method method.to_s

      unless result
        raise RuntimeError, "Unable to set up method #{method} in #{self}"
      end

      self.send method, *arguments, &block
    end

    def gir_ffi_builder
      self.const_get :GIR_FFI_BUILDER
    end

    def setup_method name
      gir_ffi_builder.setup_method name
    end
  end
end