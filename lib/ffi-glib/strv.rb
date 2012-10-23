module GLib
  # Extra methods for GLib::Strv.
  class Strv
    def self.from it
      case it
      when nil
        nil
      when FFI::Pointer
        wrap it
      when self
        it
      else
        from_enumerable it
      end
    end

    def self.from_enumerable enum
      self.wrap GirFFI::InPointer.from_array :utf8, enum
    end
  end
end
