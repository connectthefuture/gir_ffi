require 'gir_ffi/info_ext/i_registered_type_info'

module GirFFI
  module Builder
    module Argument
      # Abstract parent class of the argument building classes. These
      # classes are used by Builder::Function to create the code that
      # processes each argument before and after the actual function call.
      class Base
        KEYWORDS = [
          "alias", "and", "begin", "break", "case", "class", "def", "do",
          "else", "elsif", "end", "ensure", "false", "for", "if", "in",
          "module", "next", "nil", "not", "or", "redo", "rescue", "retry",
          "return", "self", "super", "then", "true", "undef", "unless",
          "until", "when", "while", "yield"
        ]

        attr_reader :name, :retname

        attr_accessor :length_arg, :array_arg

        def initialize var_gen, name, typeinfo, direction
          @typeinfo = typeinfo
          @inarg = nil
          @retname = nil
          @name = safe(name)
          @var_gen = var_gen
          @length_arg = nil
          @array_arg = nil
        end

        def type_info
          @typeinfo
        end

        def type_tag
          type_info.tag
        end

        def specialized_type_tag
          type_info.flattened_tag
        end

        def type_specification
          type_info.type_specification
        end

        TAG_TO_WRAPPER_CLASS_MAP = {
          :glist => 'GLib::List',
          :gslist => 'GLib::SList',
          :ghash => 'GLib::HashTable',
          :array => 'GLib::Array',
          :utf8 => 'GirFFI::InPointer',
          :void => 'GirFFI::InPointer'
        }

        def argument_class_name
          case (tag = type_tag)
          when :interface
            type_info.interface_type_name
          when :array
            case type_info.flattened_tag
            when :byte_array
              'GLib::ByteArray'
            when :array
              'GLib::Array'
            when :ptr_array
              'GLib::PtrArray'
            when :strv
              'GLib::Strv'
            else # :c
              'GirFFI::InPointer'
            end
          else
            TAG_TO_WRAPPER_CLASS_MAP[tag]
          end
        end

        def subtype_tag_or_class_name
          type_info.subtype_tag_or_class_name
        end

        def elm_t
          type_info.element_type.inspect
        end

        def array_size
          if @length_arg
            @length_arg.retname
          else
            type_info.array_fixed_size
          end
        end

        def safe name
          if KEYWORDS.include? name
            "#{name}_"
          else
            name
          end
        end

        def inarg
          @array_arg.nil? ? @inarg : nil
        end

        def retval
          @array_arg.nil? ? @retname : nil
        end

        def callarg
          @callarg ||= @var_gen.new_var
        end

        def pre
          []
        end

        def post
          []
        end

        def postpost
          []
        end

        def cleanup
          []
        end
      end
    end
  end
end

