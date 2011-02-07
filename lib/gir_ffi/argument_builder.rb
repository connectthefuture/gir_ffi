module GirFFI
  class ArgumentBuilder
    KEYWORDS =  [
      "alias", "and", "begin", "break", "case", "class", "def", "do",
      "else", "elsif", "end", "ensure", "false", "for", "if", "in",
      "module", "next", "nil", "not", "or", "redo", "rescue", "retry",
      "return", "self", "super", "then", "true", "undef", "unless",
      "until", "when", "while", "yield"
    ]

    attr_accessor :arginfo, :inarg, :callarg, :retval, :pre, :post,
      :postpost, :name, :retname

    def initialize function_builder, arginfo=nil
      @arginfo = arginfo
      @inarg = nil
      @callarg = nil
      @retval = nil
      @retname = nil
      @name = nil
      @pre = []
      @post = []
      @postpost = []
      @function_builder = function_builder
    end

    def self.build function_builder, arginfo
      klass = case arginfo.direction
              when :inout
                InOutArgumentBuilder
              when :in
                InArgumentBuilder
              when :out
                OutArgumentBuilder
              else
                raise ArgumentError
              end
      klass.new function_builder, arginfo
    end

    def safe name
      if KEYWORDS.include? name
	"#{name}_"
      else
	name
      end
    end
  end

  class InArgumentBuilder < ArgumentBuilder
    def prepare
      @name = safe(arginfo.name)
      @callarg = @function_builder.new_var
      @inarg = @name
    end

    def process
      process_in_arg
    end

    def process_in_arg
      arg = @arginfo

      case arg.type.tag
      when :interface
	@function_builder.process_interface_in_arg self
      when :void
	process_void_in_arg
      when :array
	@function_builder.process_array_in_arg self
      when :utf8
	process_utf8_in_arg
      else
	process_other_in_arg
      end

      self
    end

    def process_void_in_arg
      @pre << "#{@callarg} = GirFFI::ArgHelper.object_to_inptr #{@inarg}"
    end

    def process_utf8_in_arg
      @pre << "#{@callarg} = GirFFI::ArgHelper.utf8_to_inptr #{@name}"
      # TODO:
      #@post << "GirFFI::ArgHelper.cleanup_ptr #{@callarg}"
    end

    def process_other_in_arg
      @pre << "#{@callarg} = #{@name}"
    end
  end

  class OutArgumentBuilder < ArgumentBuilder
    def prepare
      @name = safe(arginfo.name)
      @callarg = @function_builder.new_var
      @retname = @retval = @function_builder.new_var
    end

    def process
      arg = @arginfo

      case arg.type.tag
      when :interface
	process_interface_out_arg
      when :array
	@function_builder.process_array_out_arg self
      else
	process_other_out_arg
      end

      self
    end

    def process_interface_out_arg
      arg = @arginfo
      iface = arg.type.interface

      if arg.caller_allocates?
	@pre << "#{@callarg} = #{iface.namespace}::#{iface.name}.allocate"
	@post << "#{@retval} = #{@callarg}"
      else
	@pre << "#{@callarg} = GirFFI::ArgHelper.pointer_outptr"
	tmpvar = @function_builder.new_var
	@post << "#{tmpvar} = GirFFI::ArgHelper.outptr_to_pointer #{@callarg}"
	@post << "#{@retval} = #{iface.namespace}::#{iface.name}.wrap #{tmpvar}"
      end
    end

    def process_other_out_arg
      arg = @arginfo
      tag = arg.type.tag
      @pre << "#{@callarg} = GirFFI::ArgHelper.#{tag}_outptr"
      @post << "#{@retname} = GirFFI::ArgHelper.outptr_to_#{tag} #{@callarg}"
      if arg.ownership_transfer == :everything
	@post << "GirFFI::ArgHelper.cleanup_ptr #{@callarg}"
      end
    end

  end

  class InOutArgumentBuilder < ArgumentBuilder
    def prepare
      @name = safe(arginfo.name)
      @callarg = @function_builder.new_var
      @inarg = @name
      @retname = @retval = @function_builder.new_var
    end

    def process
      arg = @arginfo

      raise NotImplementedError unless arg.ownership_transfer == :everything

      case arg.type.tag
      when :interface
	process_interface_inout_arg
      when :array
	@function_builder.process_array_inout_arg self
      else
	process_other_inout_arg
      end

      self
    end

    def process_interface_inout_arg
      raise NotImplementedError
    end

    def process_other_inout_arg
      tag = @arginfo.type.tag
      @pre << "#{@callarg} = GirFFI::ArgHelper.#{tag}_to_inoutptr #{@inarg}"
      @post << "#{@retval} = GirFFI::ArgHelper.outptr_to_#{tag} #{@callarg}"
      @post << "GirFFI::ArgHelper.cleanup_ptr #{@callarg}"
    end

  end
end
