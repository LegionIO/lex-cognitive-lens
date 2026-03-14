# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveLens::Helpers::Lens do
  let(:magnifying)  { described_class.new(lens_type: :magnifying) }
  let(:wide_angle)  { described_class.new(lens_type: :wide_angle) }
  let(:fish_eye)    { described_class.new(lens_type: :fish_eye) }
  let(:polarized)   { described_class.new(lens_type: :polarized) }
  let(:telescopic)  { described_class.new(lens_type: :telescopic) }
  let(:microscopic) { described_class.new(lens_type: :microscopic) }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(magnifying.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets lens_type' do
      expect(magnifying.lens_type).to eq(:magnifying)
    end

    it 'applies defaults from LENS_DEFAULTS for magnifying' do
      defaults = Legion::Extensions::CognitiveLens::Helpers::Constants::LENS_DEFAULTS[:magnifying]
      expect(magnifying.magnification).to be_within(0.001).of(defaults[:magnification])
      expect(magnifying.aperture).to be_within(0.001).of(defaults[:aperture])
      expect(magnifying.distortion).to be_within(0.001).of(defaults[:distortion])
    end

    it 'allows overriding defaults' do
      lens = described_class.new(lens_type: :magnifying, magnification: 3.5, clarity: 0.8)
      expect(lens.magnification).to be_within(0.001).of(3.5)
      expect(lens.clarity).to be_within(0.001).of(0.8)
    end

    it 'clamps magnification to [0.1, 10.0]' do
      lens = described_class.new(lens_type: :magnifying, magnification: 50.0)
      expect(lens.magnification).to eq(10.0)
    end

    it 'clamps clarity to [0.0, 1.0]' do
      lens = described_class.new(lens_type: :magnifying, clarity: 1.5)
      expect(lens.clarity).to eq(1.0)
    end

    it 'clamps distortion to [0.0, 1.0]' do
      lens = described_class.new(lens_type: :magnifying, distortion: -0.3)
      expect(lens.distortion).to eq(0.0)
    end

    it 'raises ArgumentError for unknown lens_type' do
      expect { described_class.new(lens_type: :quantum) }.to raise_error(ArgumentError, /unknown lens_type/)
    end

    it 'starts with no focus target' do
      expect(magnifying.focus_target).to be_nil
    end

    it 'records created_at timestamp' do
      expect(magnifying.created_at).to be_a(Time)
    end
  end

  describe '#focus!' do
    it 'sets focus target' do
      magnifying.focus!('threat_assessment')
      expect(magnifying.focus_target).to eq('threat_assessment')
    end

    it 'returns self for chaining' do
      expect(magnifying.focus!('target')).to eq(magnifying)
    end

    it 'marks lens as focused?' do
      magnifying.focus!('something')
      expect(magnifying.focused?).to be true
    end
  end

  describe '#defocus!' do
    it 'clears focus target' do
      magnifying.focus!('target')
      magnifying.defocus!
      expect(magnifying.focus_target).to be_nil
    end

    it 'returns self for chaining' do
      expect(magnifying.defocus!).to eq(magnifying)
    end

    it 'marks lens as not focused?' do
      magnifying.focus!('target')
      magnifying.defocus!
      expect(magnifying.focused?).to be false
    end
  end

  describe '#smudge!' do
    it 'reduces clarity by the smudge rate' do
      lens = described_class.new(lens_type: :magnifying, clarity: 0.8)
      lens.smudge!(0.1)
      expect(lens.clarity).to be_within(0.001).of(0.7)
    end

    it 'does not go below 0.0' do
      lens = described_class.new(lens_type: :magnifying, clarity: 0.05)
      lens.smudge!(0.5)
      expect(lens.clarity).to eq(0.0)
    end

    it 'uses default rate when not specified' do
      lens = described_class.new(lens_type: :magnifying, clarity: 1.0)
      lens.smudge!
      expect(lens.clarity).to be < 1.0
    end

    it 'returns self for chaining' do
      expect(magnifying.smudge!).to eq(magnifying)
    end
  end

  describe '#clean!' do
    it 'increases clarity by the boost amount' do
      lens = described_class.new(lens_type: :magnifying, clarity: 0.5)
      lens.clean!(0.2)
      expect(lens.clarity).to be_within(0.001).of(0.7)
    end

    it 'does not exceed 1.0' do
      lens = described_class.new(lens_type: :magnifying, clarity: 0.95)
      lens.clean!(0.5)
      expect(lens.clarity).to eq(1.0)
    end

    it 'returns self for chaining' do
      expect(magnifying.clean!).to eq(magnifying)
    end
  end

  describe '#sharp?' do
    it 'returns true when clarity is high' do
      lens = described_class.new(lens_type: :magnifying, clarity: 0.9)
      expect(lens.sharp?).to be true
    end

    it 'returns false when clarity is low' do
      lens = described_class.new(lens_type: :magnifying, clarity: 0.5)
      expect(lens.sharp?).to be false
    end
  end

  describe '#blurry?' do
    it 'returns true when clarity is very low' do
      lens = described_class.new(lens_type: :magnifying, clarity: 0.2)
      expect(lens.blurry?).to be true
    end

    it 'returns false when clarity is moderate' do
      lens = described_class.new(lens_type: :magnifying, clarity: 0.6)
      expect(lens.blurry?).to be false
    end
  end

  describe '#clarity_label' do
    it 'returns :opaque for very low clarity' do
      lens = described_class.new(lens_type: :magnifying, clarity: 0.1)
      expect(lens.clarity_label).to eq(:opaque)
    end

    it 'returns :crystal for high clarity' do
      lens = described_class.new(lens_type: :magnifying, clarity: 0.9)
      expect(lens.clarity_label).to eq(:crystal)
    end
  end

  describe '#magnification_label' do
    it 'returns :normal for 1x magnification (first matching range)' do
      lens = described_class.new(lens_type: :magnifying, magnification: 1.0)
      expect(lens.magnification_label).to eq(:normal)
    end

    it 'returns :zoom for 1.5x magnification' do
      lens = described_class.new(lens_type: :magnifying, magnification: 1.5)
      expect(lens.magnification_label).to eq(:zoom)
    end

    it 'returns :extreme for high magnification' do
      lens = described_class.new(lens_type: :telescopic)
      expect(lens.magnification_label).to eq(:extreme)
    end
  end

  describe '#depth_of_field' do
    it 'returns a value between 0 and 1' do
      expect(magnifying.depth_of_field).to be_between(0.0, 1.0)
    end

    it 'fish_eye returns a value between 0 and 1' do
      expect(fish_eye.depth_of_field).to be_between(0.0, 1.0)
    end

    it 'polarized returns a value between 0 and 1' do
      expect(polarized.depth_of_field).to be_between(0.0, 1.0)
    end

    it 'high magnification lens has different depth than low magnification' do
      high_mag = described_class.new(lens_type: :telescopic, magnification: 9.0, aperture: 0.5)
      low_mag  = described_class.new(lens_type: :wide_angle, magnification: 0.5, aperture: 0.5)
      expect(high_mag.depth_of_field).not_to eq(low_mag.depth_of_field)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = magnifying.to_h
      expect(h.keys).to include(:id, :lens_type, :magnification, :clarity, :distortion,
                                :aperture, :focus_target, :sharp, :blurry,
                                :clarity_label, :magnification_label, :depth_of_field)
    end

    it 'includes correct lens_type' do
      expect(wide_angle.to_h[:lens_type]).to eq(:wide_angle)
    end
  end
end
