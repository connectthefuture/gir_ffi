# frozen_string_literal: true
require 'gir_ffi/builders/registered_type_builder'
require 'gir_ffi/builders/struct_like'
require 'gir_ffi/struct_base'

module GirFFI
  module Builders
    # Implements the creation of a class representing a Struct.
    class StructBuilder < RegisteredTypeBuilder
      include StructLike

      def layout_superclass
        FFI::Struct
      end

      def superclass
        if info.gtype_struct?
          # HACK: Inheritance chain is not expressed in GObject's code correctly.
          if info.full_type_name == 'GObject::InitiallyUnownedClass'
            return GObject::ObjectClass
          else
            type = fields.first.field_type
            return type.tag_or_class if type.tag == :interface
          end
        end

        StructBase
      end
    end
  end
end
