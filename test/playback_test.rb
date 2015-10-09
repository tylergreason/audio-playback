require "helper"

class AudioPlayback::PlaybackTest < Minitest::Test

  context "Playback" do

    setup do
      @path = "test/media/1-mono-44100.wav"
      @sound = AudioPlayback::Sound.load(@path)
      @output = AudioPlayback::Output.by_id(0)
    end

    context ".play" do

      setup do
        AudioPlayback::Stream.any_instance.expects(:start).once.returns(true)
      end

      teardown do
        AudioPlayback::Stream.any_instance.unstub(:start)
      end

      should "start playback" do
        @playback = AudioPlayback::Playback.play(@sound, @output)
        refute_nil @playback
        assert_kind_of AudioPlayback::Playback, @playback
      end

    end

    context "#start" do

      setup do
        @playback = AudioPlayback::Playback.new(@sound, @output)
        AudioPlayback::Stream.any_instance.expects(:start).once.returns(true)
      end

      teardown do
        AudioPlayback::Stream.any_instance.unstub(:start)
      end

      should "start playback" do
        @result = @playback.start
        assert_kind_of AudioPlayback::Playback, @result
      end

    end

    context "#block" do

    end

    context "#report" do

      setup do
        @logger = Object.new
        @playback = AudioPlayback::Playback.new(@sound, @output)
        @logger.expects(:puts).once
      end

      should "do logging" do
        assert @playback.report(@logger)
      end

    end

    context "#data_size" do

    end

    context "#frames" do

    end

    context "#ensure_structure" do

      context "sound has same number of channels as output" do

        context "mono file, mono output" do

          setup do
            @path = "test/media/1-mono-44100.wav"
            @file = AudioPlayback::File.new(@path)
            @sound = AudioPlayback::Sound.new(@file)
            @output = MockOutput.new(1, :num_channels => 1)
            @playback = AudioPlayback::Playback.new(@sound, @output, :stream => MockStream.new(@output))
            @data = @sound.data
            @frames = @playback.frames.slice(AudioPlayback::Playback::METADATA.size..-1)
          end

          should "have two channels of valid data" do
            refute_nil @frames
            assert @frames.kind_of?(Array)
            refute_empty @frames
            assert @frames.all? { |frame_channels| frame_channels.count == @output.num_channels }
            assert @frames.all? { |frame_channels| frame_channels.count == @sound.num_channels }
            assert @frames.all? { |frame_channels| frame_channels.all? { |frame| frame.kind_of?(Float) } }
          end

        end

        context "stereo file, stereo output" do

          setup do
            @path = "test/media/1-stereo-44100.wav"
            @file = AudioPlayback::File.new(@path)
            @sound = AudioPlayback::Sound.new(@file)
            @output = MockOutput.new(1, :num_channels => 2)
            @playback = AudioPlayback::Playback.new(@sound, @output, :stream => MockStream.new(@output))
            @data = @sound.data
            @frames = @playback.frames.slice(AudioPlayback::Playback::METADATA.size..-1)
          end

          should "have one channel of valid data" do
            refute_nil @frames
            assert @frames.kind_of?(Array)
            refute_empty @frames
            assert @frames.all? { |frame_channels| frame_channels.kind_of?(Array) }
            assert @frames.all? { |frame_channels| frame_channels.count == @output.num_channels }
            assert @frames.all? { |frame_channels| frame_channels.count == @sound.num_channels }
            assert @frames.all? { |frame_channels| frame_channels.all? { |frame| frame.kind_of?(Float) } }
          end

        end

      end

      context "sound has different number of channels than output" do

        context "mono file, stereo output" do

          setup do
            @path = "test/media/1-mono-44100.wav"
            @file = AudioPlayback::File.new(@path)
            @sound = AudioPlayback::Sound.new(@file)
            @output = MockOutput.new(1, :num_channels => 2)
            @playback = AudioPlayback::Playback.new(@sound, @output, :stream => MockStream.new(@output))
            @data = @sound.data
            @frames = @playback.frames.slice(AudioPlayback::Playback::METADATA.size..-1)
          end

          should "have two channels of valid data" do
            refute_nil @frames
            assert @frames.kind_of?(Array)
            refute_empty @frames
            assert @frames.all? { |frame_channels| frame_channels.count == @output.num_channels }
            refute @frames.any? { |frame_channels| frame_channels.count == @sound.num_channels }
            assert @frames.all? { |frame_channels| frame_channels.all? { |frame| frame.kind_of?(Float) } }
          end

        end

        context "stereo file, mono output" do

          setup do
            @path = "test/media/1-stereo-44100.wav"
            @file = AudioPlayback::File.new(@path)
            @sound = AudioPlayback::Sound.new(@file)
            @output = MockOutput.new(1, :num_channels => 1)
            @playback = AudioPlayback::Playback.new(@sound, @output, :stream => MockStream.new(@output))
            @data = @sound.data
            @frames = @playback.frames.slice(AudioPlayback::Playback::METADATA.size..-1)
          end

          should "have one channel of valid data" do
            refute_nil @frames
            assert @frames.kind_of?(Array)
            refute_empty @frames
            assert @frames.all? { |frame_channels| frame_channels.kind_of?(Array) }
            assert @frames.all? { |frame_channels| frame_channels.count == @output.num_channels }
            refute @frames.any? { |frame_channels| frame_channels.count == @sound.num_channels }
            assert @frames.all? { |frame_channels| frame_channels.all? { |frame| frame.kind_of?(Float) } }
          end

        end

      end

    end

  end

end
