module GirFFI
  # Abstract parent class of the argument building classes. These classes
  # are used by FunctionDefinitionBuilder to create the code that processes
  # each argument before and after the actual function call.
  class ArgumentBuilder
    KEYWORDS =  [
      "alias", "and", "begin", "break", "case", "class", "def", "do",
      "else", "elsif", "end", "ensure", "false", "for", "if", "in",
      "module", "next", "nil", "not", "or", "redo", "rescue", "retry",
      "return", "self", "super", "then", "true", "undef", "unless",
      "until", "when", "while", "yield"
    ]

    attr_reader :arginfo, :callarg, :pre, :post, :postpost

    attr_accessor :length_arg, :inarg, :retval

    def initialize function_builder, arginfo=nil, libmodule=nil
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
      @libmodule = libmodule
    end

    def self.build function_builder, arginfo, libmodule
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
      klass.new function_builder, arginfo, libmodule
    end

    private

    def safe name
      if KEYWORDS.include? name
	"#{name}_"
      else
	name
      end
    end
  end

  # Implements argument processing for arguments with direction :in
  class InArgumentBuilder < ArgumentBuilder
    def prepare
      @name = safe(@arginfo.name)
      @callarg = @function_builder.new_var
      @inarg = @name
    end

    def process
      case @arginfo.type.tag
      when :interface
	process_interface_in_arg
      when :void
	process_void_in_arg
      when :array
	process_array_in_arg
      when :utf8
	process_utf8_in_arg
      else
	process_other_in_arg
      end
    end

    private


    def process_interface_in_arg
      arg = @arginfo
      type = arg.type

      iface = type.interface
      if iface.type == :callback
	@pre << "#{@callarg} = GirFFI::ArgHelper.wrap_in_callback_args_mapper \"#{iface.namespace}\", \"#{iface.name}\", #{@inarg}"
	@pre << "::#{@libmodule}::CALLBACKS << #{@callarg}"
      else
	@pre << "#{@callarg} = #{@inarg}"
      end
    end

    def process_void_in_arg
      @pre << "#{@callarg} = GirFFI::ArgHelper.object_to_inptr #{@inarg}"
    end

    def process_utf8_in_arg
      @pre << "#{@callarg} = GirFFI::ArgHelper.utf8_to_inptr #{@name}"
      # TODO:
      #@post << "GirFFI::ArgHelper.cleanup_ptr #{@callarg}"
    end

    def process_array_in_arg
      arg = @arginfo
      type = arg.type

      if type.array_fixed_size > 0
	@pre << "GirFFI::ArgHelper.check_fixed_array_size #{type.array_fixed_size}, #{@inarg}, \"#{@inarg}\""
      elsif type.array_length > -1
	idx = type.array_length
	lenvar = @length_arg.inarg
	@length_arg.inarg = nil
	@length_arg.pre.unshift "#{lenvar} = #{@inarg}.nil? ? 0 : #{@inarg}.length"
      end

      tag = arg.type.param_type(0).tag.to_s.downcase
      @pre << "#{@callarg} = GirFFI::ArgHelper.#{tag}_array_to_inptr #{@inarg}"
      unless arg.ownership_transfer == :everything
	if tag == :utf8
	  @post << "GirFFI::ArgHelper.cleanup_ptr_ptr #{@callarg}"
	else
	  @post << "GirFFI::ArgHelper.cleanup_ptr #{@callarg}"
	end
      end
    end

    def process_other_in_arg
      @pre << "#{@callarg} = #{@name}"
    end
  end

  # Implements argument processing for arguments with direction :out
  class OutArgumentBuilder < ArgumentBuilder
    def prepare
      @name = safe(@arginfo.name)
      @callarg = @function_builder.new_var
      @retname = @retval = @function_builder.new_var
    end

    def process
      case @arginfo.type.tag
      when :interface
	process_interface_out_arg
      when :array
	process_array_out_arg
      else
	process_other_out_arg
      end
    end

    private

    def process_interface_out_arg
      iface = @arginfo.type.interface
      klass = "#{iface.namespace}::#{iface.name}"

      if @arginfo.caller_allocates?
	@pre << "#{@callarg} = #{klass}.allocate"
	@post << "#{@retval} = #{@callarg}"
      else
	@pre << "#{@callarg} = GirFFI::ArgHelper.pointer_outptr"
	@post << "#{@retval} = #{klass}.wrap GirFFI::ArgHelper.outptr_to_pointer(#{@callarg})"
      end
    end

    def process_array_out_arg
      @pre << "#{@callarg} = GirFFI::ArgHelper.pointer_outptr"

      arg = @arginfo
      type = arg.type
      tag = type.param_type(0).tag
      size = type.array_fixed_size
      idx = type.array_length

      if size <= 0
	if idx > -1
	  size = @length_arg.retval
	  @length_arg.retval = nil
	else
	  raise NotImplementedError
	end
      end

      @postpost << "#{@retval} = GirFFI::ArgHelper.outptr_to_#{tag}_array #{@callarg}, #{size}"

      if arg.ownership_transfer == :everything
	if tag == :utf8
	  @postpost << "GirFFI::ArgHelper.cleanup_ptr_array_ptr #{@callarg}, #{rv}"
	else
	  @postpost << "GirFFI::ArgHelper.cleanup_ptr_ptr #{@callarg}"
	end
      end
    end

    def process_other_out_arg
      tag = @arginfo.type.tag
      @pre << "#{@callarg} = GirFFI::ArgHelper.#{tag}_outptr"
      @post << "#{@retname} = GirFFI::ArgHelper.outptr_to_#{tag} #{@callarg}"
      if @arginfo.ownership_transfer == :everything
	@post << "GirFFI::ArgHelper.cleanup_ptr #{@callarg}"
      end
    end

  end

  # Implements argument processing for arguments with direction :inout
  class InOutArgumentBuilder < ArgumentBuilder
    def prepare
      @name = safe(@arginfo.name)
      @callarg = @function_builder.new_var
      @inarg = @name
      @retname = @retval = @function_builder.new_var
    end

    def process
      raise NotImplementedError unless @arginfo.ownership_transfer == :everything

      case @arginfo.type.tag
      when :interface
	process_interface_inout_arg
      when :array
	process_array_inout_arg
      else
	process_other_inout_arg
      end
    end

    private

    def process_interface_inout_arg
      raise NotImplementedError
    end

    def process_array_inout_arg
      arg = @arginfo
      tag = arg.type.param_type(0).tag
      @pre << "#{@callarg} = GirFFI::ArgHelper.#{tag}_array_to_inoutptr #{@inarg}"
      if arg.type.array_length > -1
	idx = arg.type.array_length
	rv = @length_arg.retval
	@length_arg.retval = nil
	lname = @length_arg.inarg
	@length_arg.inarg = nil
	@length_arg.pre.unshift "#{lname} = #{@inarg}.length"
	@post << "#{@retval} = GirFFI::ArgHelper.outptr_to_#{tag}_array #{@callarg}, #{rv}"
	if tag == :utf8
	  @post << "GirFFI::ArgHelper.cleanup_ptr_array_ptr #{@callarg}, #{rv}"
	else
	  @post << "GirFFI::ArgHelper.cleanup_ptr_ptr #{@callarg}"
	end
      else
	raise NotImplementedError
      end
    end

    def process_other_inout_arg
      tag = @arginfo.type.tag
      @pre << "#{@callarg} = GirFFI::ArgHelper.#{tag}_to_inoutptr #{@inarg}"
      @post << "#{@retval} = GirFFI::ArgHelper.outptr_to_#{tag} #{@callarg}"
      @post << "GirFFI::ArgHelper.cleanup_ptr #{@callarg}"
    end
  end

  class ReturnValueBuilder < ArgumentBuilder
    attr_reader :cvar

    def prepare
      return if tag == :void
      @cvar = @function_builder.new_var
      @retval = @function_builder.new_var
    end

    def process
      return if tag == :void

      type = @arginfo.return_type

      case tag
      when :interface
	process_interface_return_value type, @cvar
      when :array
	process_array_return_value type, @cvar
      else
	process_other_return_value
      end
    end

    private

    def process_interface_return_value type, cvar
      interface = type.interface
      namespace = interface.namespace
      name = interface.name

      case interface.type
      when :interface
	GirFFI::Builder.build_class namespace, name
	@post << "#{@retval} = ::#{namespace}::#{name}.wrap(#{cvar})"
      when :object
	if @arginfo.constructor?
	  GirFFI::Builder.build_class namespace, name
	  @post << "#{@retval} = ::#{namespace}::#{name}.wrap(#{cvar})"
          if is_subclass_of_initially_unowned interface
            @post << "GirFFI::GObject.object_ref_sink(#{@retval})"
          end
	else
	  @post << "#{@retval} = GirFFI::ArgHelper.object_pointer_to_object(#{cvar})"
	end
      when :struct
	GirFFI::Builder.build_class namespace, name
	@post << "#{@retval} = ::#{namespace}::#{name}.wrap(#{cvar})"
      else
	@post << "#{@retval} = #{cvar}"
      end
    end

    def process_array_return_value type, cvar
      tag = type.param_type(0).tag
      size = type.array_fixed_size
      idx = type.array_length

      if size > 0
	@post << "#{@retval} = GirFFI::ArgHelper.ptr_to_#{tag}_array #{cvar}, #{size}"
      elsif idx > -1
	lendata = @length_arg #@data[idx]
	rv = lendata.retval
	lendata.retval = nil
	@post << "#{@retval} = GirFFI::ArgHelper.ptr_to_#{tag}_array #{cvar}, #{rv}"
      end
    end

    def process_other_return_value
      @retval = @cvar
    end

    def tag
      @arginfo.return_type.tag
    end

    def is_subclass_of_initially_unowned interface
      if interface.namespace == "GObject" and interface.name == "InitiallyUnowned"
        true
      elsif interface.parent
        is_subclass_of_initially_unowned interface.parent
      else
        false
      end
    end
  end
end