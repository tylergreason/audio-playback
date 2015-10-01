module SamplePlayer

  class Playback

    extend Forwardable

    attr_reader :frame_size, :data, :sample
    def_delegators :@sample, :audio_file, :num_channels, :sample_rate, :size

    DEFAULT = {
      :frame_size => 2**12
    }.freeze

    def initialize(sample, options = {})
      @sample = sample
      @frame_size = options[:frame_size] || DEFAULT[:frame_size] #File.size(filename)
      populate
    end

    def size_in_bytes
      @sample.size * FFI::TYPE_FLOAT32.size
    end

    private

    def pointer(data)
      pointer = LibC.malloc(size_in_bytes + 1)
      pointer.write_array_of_float(data)
      pointer
    end

    def populate
      data = @sample.data
      data.unshift(@sample.size)
      @data = pointer(data)
    end
  end

end
