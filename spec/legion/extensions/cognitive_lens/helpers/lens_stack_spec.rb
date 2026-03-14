# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveLens::Helpers::LensStack do
  let(:lens_class) { Legion::Extensions::CognitiveLens::Helpers::Lens }
  let(:stack)      { described_class.new }

  let(:magnifying)  { lens_class.new(lens_type: :magnifying, magnification: 2.0, clarity: 1.0, distortion: 0.1) }
  let(:wide_angle)  { lens_class.new(lens_type: :wide_angle, magnification: 0.5, clarity: 0.9, distortion: 0.2) }
  let(:polarized)   { lens_class.new(lens_type: :polarized,  magnification: 1.0, clarity: 0.8, distortion: 0.0) }

  describe '#push_lens' do
    it 'adds a lens to the stack' do
      stack.push_lens(magnifying)
      expect(stack.size).to eq(1)
    end

    it 'returns self for chaining' do
      expect(stack.push_lens(magnifying)).to eq(stack)
    end

    it 'raises ArgumentError for non-Lens objects' do
      expect { stack.push_lens('not_a_lens') }.to raise_error(ArgumentError, /expected a Lens/)
    end

    it 'raises ArgumentError when stack is full' do
      lens_count = Legion::Extensions::CognitiveLens::Helpers::Constants::MAX_LENSES
      lens_count.times { stack.push_lens(lens_class.new(lens_type: :magnifying)) }
      expect { stack.push_lens(lens_class.new(lens_type: :wide_angle)) }.to raise_error(ArgumentError, /stack is full/)
    end
  end

  describe '#pop_lens' do
    it 'removes and returns the last lens' do
      stack.push_lens(magnifying)
      stack.push_lens(wide_angle)
      popped = stack.pop_lens
      expect(popped).to eq(wide_angle)
      expect(stack.size).to eq(1)
    end

    it 'returns nil when stack is empty' do
      expect(stack.pop_lens).to be_nil
    end
  end

  describe '#empty?' do
    it 'returns true for new stack' do
      expect(stack.empty?).to be true
    end

    it 'returns false after pushing a lens' do
      stack.push_lens(magnifying)
      expect(stack.empty?).to be false
    end
  end

  describe '#combined_magnification' do
    it 'returns 1.0 for empty stack' do
      expect(stack.combined_magnification).to eq(1.0)
    end

    it 'applies sub-linear compounding for single lens' do
      stack.push_lens(magnifying)
      expected = (2.0**Legion::Extensions::CognitiveLens::Helpers::Constants::STACK_MAGNIFICATION_EXPONENT)
      expect(stack.combined_magnification).to be_within(0.001).of(expected)
    end

    it 'compounds magnification for multiple lenses' do
      stack.push_lens(magnifying)
      stack.push_lens(wide_angle)
      expect(stack.combined_magnification).to be > 0.0
    end
  end

  describe '#combined_distortion' do
    it 'returns 0.0 for empty stack' do
      expect(stack.combined_distortion).to eq(0.0)
    end

    it 'returns lens distortion for single lens' do
      stack.push_lens(polarized)
      expect(stack.combined_distortion).to eq(0.0)
    end

    it 'blends toward worst distortion for multiple lenses' do
      stack.push_lens(magnifying)  # 0.1 distortion
      stack.push_lens(wide_angle)  # 0.2 distortion
      expect(stack.combined_distortion).to be_between(0.1, 0.2)
    end

    it 'is clamped between 0 and 1' do
      stack.push_lens(lens_class.new(lens_type: :fish_eye))
      expect(stack.combined_distortion).to be_between(0.0, 1.0)
    end
  end

  describe '#stack_clarity' do
    it 'returns 1.0 for empty stack' do
      expect(stack.stack_clarity).to eq(1.0)
    end

    it 'returns lens clarity for single lens' do
      stack.push_lens(polarized)
      expect(stack.stack_clarity).to be <= polarized.clarity
    end

    it 'decays clarity with each additional lens' do
      stack.push_lens(magnifying)
      single_clarity = stack.stack_clarity

      stack.push_lens(wide_angle)
      expect(stack.stack_clarity).to be < single_clarity
    end

    it 'is clamped between 0 and 1' do
      3.times { stack.push_lens(lens_class.new(lens_type: :magnifying, clarity: 0.5)) }
      expect(stack.stack_clarity).to be_between(0.0, 1.0)
    end
  end

  describe '#view_through' do
    it 'returns original content when stack is empty' do
      expect(stack.view_through(0.6)).to eq(0.6)
    end

    it 'returns a result hash with expected keys' do
      stack.push_lens(magnifying)
      result = stack.view_through(0.5)
      expect(result.keys).to include(:original, :perceived, :combined_magnification,
                                     :combined_distortion, :stack_clarity, :lens_count, :focus_active)
    end

    it 'preserves neutral value (0.5) through neutral magnification' do
      lens = lens_class.new(lens_type: :polarized, magnification: 1.0, distortion: 0.0, clarity: 1.0)
      stack.push_lens(lens)
      result = stack.view_through(0.5)
      expect(result[:perceived]).to be_within(0.05).of(0.5)
    end

    it 'magnifies values away from center' do
      stack.push_lens(magnifying)
      result = stack.view_through(0.8)
      expect(result[:perceived]).to be > 0.5
    end

    it 'accepts hash content with :value key' do
      stack.push_lens(magnifying)
      result = stack.view_through({ value: 0.7 })
      expect(result[:original]).to be_within(0.001).of(0.7)
    end

    it 'reports focus_active as true when a lens is focused' do
      magnifying.focus!('target')
      stack.push_lens(magnifying)
      result = stack.view_through(0.5)
      expect(result[:focus_active]).to be true
    end

    it 'reports focus_active as false when no lens is focused' do
      stack.push_lens(magnifying)
      result = stack.view_through(0.5)
      expect(result[:focus_active]).to be false
    end
  end

  describe '#to_h' do
    it 'includes stack summary fields' do
      stack.push_lens(magnifying)
      h = stack.to_h
      expect(h.keys).to include(:lens_count, :combined_magnification, :combined_distortion,
                                :stack_clarity, :lenses)
    end

    it 'includes lens details' do
      stack.push_lens(magnifying)
      expect(stack.to_h[:lenses].size).to eq(1)
    end
  end
end
