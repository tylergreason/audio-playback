require "helper"

class AudioPlayback::OutputTest < Minitest::Test

  context "Output" do

    setup do
      @outputs = AudioPlayback::Output.all
    end

    context ".all" do

      should "return available outputs" do
        refute_nil @outputs
        refute_empty @outputs
        assert_equal TestHelper::OUTPUT_INFO.map { |info| info[:name] }, @outputs.map(&:name)
      end

    end

    context ".by_id" do

      should "return an output with the given id" do
        @outputs.each do |output|
          assert_equal output, AudioPlayback::Output.by_id(output.id)
        end
      end

    end

    context ".by_name" do

      should "return an output with the given name" do
        @outputs.each do |output|
          assert_equal output, AudioPlayback::Output.by_name(output.name)
        end
      end

    end

    context "#populate" do

      setup do
        @id = 0
        @output = AudioPlayback::Output.new(@id)
      end

      should "populate id" do
        refute_nil @output.id
        assert_kind_of Fixnum, @output.id
      end

      should "populate latency" do
        refute_nil @output.latency
        assert_kind_of Numeric, @output.latency
      end

      should "populate number of channels" do
        refute_nil @output.num_channels
        assert_kind_of Fixnum, @output.num_channels
      end

      should "populate name" do
        refute_nil @output.name
        assert_kind_of String, @output.name
        assert_equal "Test Output #{@id+1}", @output.name
      end

    end

    context "#latency" do

      setup do
        @test_id = (0..TestHelper::OUTPUT_INFO.size-1).to_a.sample
        @test_info = TestHelper::OUTPUT_INFO[@test_id]
      end

      context "latency option" do

        setup do
          @output = AudioPlayback::Output.new(@test_id, :latency => 20)
        end

        should "return correct latency" do
          refute_nil @output.latency
          assert_kind_of Float, @output.latency
          assert_equal 20, @output.latency
        end

      end

      context "no options" do

        setup do
          @output = AudioPlayback::Output.new(@test_id)
        end

        should "return correct latency" do
          refute_nil @output.latency
          assert_kind_of Float, @output.latency
          assert_equal @test_info[:defaultHighOutputLatency], @output.latency
        end

      end

    end

    context "#num_channels" do

      setup do
        @test_id = (0..TestHelper::OUTPUT_INFO.size-1).to_a.sample
        @test_info = TestHelper::OUTPUT_INFO[@test_id]
      end

      context "num_channels option" do

        context "valid" do

          setup do
            @output = AudioPlayback::Output.new(@test_id, :num_channels => 1)
          end

          should "return correct num_channels" do
            refute_nil @output.num_channels
            assert_kind_of Fixnum, @output.num_channels
            assert_equal 1, @output.num_channels
          end

        end

        context "invalid" do

          should "raise exception" do
            assert_raises(RuntimeError) do
              @output = AudioPlayback::Output.new(@test_id, :num_channels => @test_info[:maxOutputChannels] + 20)
            end
          end

        end

      end

      context "no options" do

        setup do
          @output = AudioPlayback::Output.new(@test_id)
        end

        should "return correct num_channels" do
          refute_nil @output.num_channels
          assert_kind_of Fixnum, @output.num_channels
          assert_equal @test_info[:maxOutputChannels], @output.num_channels
        end

      end

    end

    context "#id" do

      setup do
        @test_id = (0..TestHelper::OUTPUT_INFO.size-1).to_a.sample
        @output = AudioPlayback::Output.new(@test_id)
      end

      should "return correct id" do
        refute_nil @output.id
        assert_kind_of Fixnum, @output.id
        assert_equal @test_id, @output.id
      end

    end

  end

end