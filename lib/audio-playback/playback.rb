module AudioPlayback

  # Action of playing back an audio file
  class Playback

    extend Forwardable

    attr_reader :buffer_size, :data, :num_channels, :sound, :stream
    def_delegators :@sound, :audio_file, :sample_rate, :size

    DEFAULT = {
      :buffer_size => 2**12
    }.freeze

    FRAME_SIZE = FFI::TYPE_FLOAT32.size

    METADATA = [:size, :num_channels, :pointer, :is_eof].freeze

    # @param [Sound] sound
    # @param [Output] output
    # @param [Hash] options
    # @option options [Fixnum] :buffer_size
    # @option options [Array<Fixnum>, Fixnum] :channels (or: :channel)
    # @option options [IO] :logger
    # @option options [Stream] :stream
    # @return [Playback]
    def self.play(sound, output, options = {})
      playback = new(sound, output, options)
      playback.start
    end

    # @param [Sound] sound
    # @param [Output] output
    # @param [Hash] options
    # @option options [Fixnum] :buffer_size
    # @option options [Array<Fixnum>, Fixnum] :channels (or: :channel)
    # @option options [IO] :logger
    # @option options [Stream] :stream
    def initialize(sound, output, options = {})
      @sound = sound
      @buffer_size = options[:buffer_size] || DEFAULT[:buffer_size]
      @output = output
      @stream = options[:stream] || Stream.new(@output, options)
      populate(options)
      report(options[:logger]) if options[:logger]
    end

    # Start playback
    # @return [Playback]
    def start
      @stream.play(self)
      self
    end

    # Block process until playback finishes
    # @return [Stream]
    def block
      @stream.block
    end

    # Log a report about playback
    # @param [IO] logger
    # @return [Boolean]
    def report(logger)
      logger.puts("Playback report for #{@sound.audio_file.path}")
      logger.puts("  Number of channels: #{@num_channels}")
      logger.puts("  Direct audio to channels #{@channels.to_s}") unless @channels.nil?
      logger.puts("  Buffer size: #{@buffer_size}")
      logger.puts("  Latency: #{@output.latency}")
      true
    end

    # Total size of the playback's sound frames in bytes
    # @return [Fixnum]
    def data_size
      frames = (@sound.size * @num_channels) + METADATA.count
      frames * FRAME_SIZE.size
    end

    # Sound frames
    # @return [Array<Array<Float>>]
    def frames
      @frames ||= ensure_structure(@sound.data.dup)
    end

    private

    def pointer(data)
      pointer = FFI::LibC.malloc(data_size)
      pointer.write_array_of_float(data)
      pointer
    end

    def ensure_structure(data)
      data = ensure_array_frames(data)
      if @sound.num_channels == @num_channels && @channels.nil?
        data
      else
        ensure_num_channels(data, @num_channels)
        if @channels.nil?
          if @num_channels != @output.num_channels
            ensure_num_channels(data, @output.num_channels)
          end
        else
          ensure_num_channels(data, @output.num_channels, :channels => @channels)
        end
        data
      end
    end

    def fill_frame_for_channels(frame, size, channels)
      values = frame.dup
      frame.fill(0, 0, size)
      channels.each do |channel|
        value = values[channel] || values.first
        frame[channel] = value
      end
    end

    def fill_frame(frame, size, difference, options = {})
      if (channels = options[:channels]).nil?
        frame.fill(frame.last, frame.size, difference)
      else
        fill_frame_for_channels(frame, size, channels)
      end
    end

    def ensure_num_channels(data, num, options = {})
      data.each do |frame|
        difference = num - frame.size
        if difference > 0
          fill_frame(frame, num, difference, :channels => options[:channels])
        else
          frame.slice!(num..-1)
        end
      end
    end

    def ensure_array_frames(data)
      if data.sample.kind_of?(Array)
        data
      else
        data.map { |frame| Array(frame) }
      end
    end

    def add_metadata(data)
      data.unshift(0.0) # 3. is_eof
      data.unshift(0.0) # 2. counter
      data.unshift(@output.num_channels.to_f) # 1. num_channels
      data.unshift(@sound.size.to_f) # 0. sample size
      data
    end

    def validate_requested_channels(channels)
      if channels.count > @output.num_channels
        raise "Only #{@output.num_channels} channels available on #{@output.name} output"
        false
      end
      true
    end

    def populate_requested_channels(request)
      request = Array(request)
      requested_channels = request.map(&:to_i).uniq
      if validate_requested_channels(requested_channels)
        @num_channels = requested_channels.count
        @channels = requested_channels
      end
    end

    def populate_channels(options = {})
      request = options[:channels] || options[:channel]
      if request.nil?
        @num_channels = @output.num_channels
      else
        populate_requested_channels(request)
      end
    end

    def populate(options = {})
      populate_channels(options)
      data = frames
      add_metadata(data)
      @data = pointer(data.flatten)
    end
  end

end
