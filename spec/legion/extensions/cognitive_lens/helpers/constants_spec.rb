# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveLens::Helpers::Constants do
  describe 'LENS_TYPES' do
    it 'contains 6 lens types' do
      expect(described_class::LENS_TYPES.size).to eq(6)
    end

    it 'includes all expected types' do
      expect(described_class::LENS_TYPES).to include(:magnifying, :wide_angle, :fish_eye, :polarized, :telescopic, :microscopic)
    end

    it 'is frozen' do
      expect(described_class::LENS_TYPES).to be_frozen
    end
  end

  describe 'DISTORTION_TYPES' do
    it 'contains expected distortion modes' do
      expect(described_class::DISTORTION_TYPES).to include(:none, :barrel, :pincushion)
    end

    it 'is frozen' do
      expect(described_class::DISTORTION_TYPES).to be_frozen
    end
  end

  describe 'MAX_LENSES' do
    it 'is 8' do
      expect(described_class::MAX_LENSES).to eq(8)
    end
  end

  describe 'CLARITY_LABELS' do
    it 'covers the full 0..1 range' do
      all_values_covered = [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0].all? do |v|
        described_class::CLARITY_LABELS.any? { |range, _| range.cover?(v) }
      end
      expect(all_values_covered).to be true
    end

    it 'labels low clarity as opaque or foggy' do
      label = described_class::CLARITY_LABELS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:opaque)
    end

    it 'labels high clarity as crystal' do
      label = described_class::CLARITY_LABELS.find { |range, _| range.cover?(0.95) }&.last
      expect(label).to eq(:crystal)
    end
  end

  describe 'MAGNIFICATION_LABELS' do
    it 'labels 1.5x as zoom' do
      label = described_class::MAGNIFICATION_LABELS.find { |range, _| range.cover?(1.5) }&.last
      expect(label).to eq(:zoom)
    end

    it 'labels 0.7x as normal' do
      label = described_class::MAGNIFICATION_LABELS.find { |range, _| range.cover?(0.7) }&.last
      expect(label).to eq(:normal)
    end

    it 'labels 7.0x as extreme' do
      label = described_class::MAGNIFICATION_LABELS.find { |range, _| range.cover?(7.0) }&.last
      expect(label).to eq(:extreme)
    end
  end

  describe 'LENS_DEFAULTS' do
    it 'has defaults for every lens type' do
      described_class::LENS_TYPES.each do |lt|
        expect(described_class::LENS_DEFAULTS).to have_key(lt)
      end
    end

    it 'fish_eye has maximum aperture' do
      expect(described_class::LENS_DEFAULTS[:fish_eye][:aperture]).to eq(1.0)
    end

    it 'polarized has zero distortion' do
      expect(described_class::LENS_DEFAULTS[:polarized][:distortion]).to eq(0.0)
    end

    it 'telescopic and microscopic have the highest default magnifications' do
      mags = described_class::LENS_DEFAULTS.transform_values { |d| d[:magnification] }
      high_mags = mags.values.sort.last(2)
      expect(mags[:telescopic]).to be >= high_mags.first
    end
  end
end
