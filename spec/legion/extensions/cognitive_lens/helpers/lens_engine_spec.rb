# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveLens::Helpers::LensEngine do
  let(:engine) { described_class.new }

  describe '#create_lens' do
    it 'creates and registers a lens' do
      lens = engine.create_lens(lens_type: :magnifying)
      expect(engine.lenses[lens.id]).to eq(lens)
    end

    it 'returns a Lens instance' do
      lens = engine.create_lens(lens_type: :wide_angle)
      expect(lens).to be_a(Legion::Extensions::CognitiveLens::Helpers::Lens)
    end

    it 'passes custom magnification' do
      lens = engine.create_lens(lens_type: :magnifying, magnification: 3.0)
      expect(lens.magnification).to be_within(0.001).of(3.0)
    end

    it 'passes custom clarity' do
      lens = engine.create_lens(lens_type: :magnifying, clarity: 0.6)
      expect(lens.clarity).to be_within(0.001).of(0.6)
    end

    it 'creates multiple lenses with different ids' do
      l1 = engine.create_lens(lens_type: :magnifying)
      l2 = engine.create_lens(lens_type: :wide_angle)
      expect(l1.id).not_to eq(l2.id)
    end
  end

  describe '#stack_lenses' do
    let(:lens1) { engine.create_lens(lens_type: :magnifying) }
    let(:lens2) { engine.create_lens(lens_type: :wide_angle) }

    it 'creates a stack from lens ids' do
      result = engine.stack_lenses(lens_ids: [lens1.id, lens2.id])
      expect(result[:stack]).to be_a(Legion::Extensions::CognitiveLens::Helpers::LensStack)
    end

    it 'registers the stack with an auto-generated id' do
      result = engine.stack_lenses(lens_ids: [lens1.id])
      expect(engine.stacks[result[:stack_id]]).to be_a(Legion::Extensions::CognitiveLens::Helpers::LensStack)
    end

    it 'uses provided stack_id' do
      result = engine.stack_lenses(lens_ids: [lens1.id], stack_id: 'my-stack')
      expect(result[:stack_id]).to eq('my-stack')
    end

    it 'raises ArgumentError for unknown lens id' do
      expect { engine.stack_lenses(lens_ids: ['unknown-id']) }.to raise_error(ArgumentError, /lens not found/)
    end
  end

  describe '#view_through_stack' do
    let(:lens) { engine.create_lens(lens_type: :magnifying) }
    let(:stack_result) { engine.stack_lenses(lens_ids: [lens.id]) }
    let(:stack_id) { stack_result[:stack_id] }

    it 'returns view result for existing stack' do
      result = engine.view_through_stack(stack_id: stack_id, content: 0.6)
      expect(result).to have_key(:perceived)
    end

    it 'raises ArgumentError for unknown stack id' do
      expect { engine.view_through_stack(stack_id: 'bad-id', content: 0.5) }
        .to raise_error(ArgumentError, /stack not found/)
    end
  end

  describe '#degrade_all!' do
    it 'reduces clarity on all lenses' do
      l1 = engine.create_lens(lens_type: :magnifying, clarity: 1.0)
      l2 = engine.create_lens(lens_type: :wide_angle, clarity: 1.0)
      engine.degrade_all!
      expect(l1.clarity).to be < 1.0
      expect(l2.clarity).to be < 1.0
    end

    it 'returns degraded count and rate' do
      engine.create_lens(lens_type: :magnifying)
      result = engine.degrade_all!(rate: 0.05)
      expect(result[:degraded]).to eq(1)
      expect(result[:rate]).to eq(0.05)
    end

    it 'handles empty lens set gracefully' do
      result = engine.degrade_all!
      expect(result[:degraded]).to eq(0)
    end
  end

  describe '#clearest_lenses' do
    it 'returns lenses sorted by clarity descending' do
      engine.create_lens(lens_type: :magnifying, clarity: 0.5)
      engine.create_lens(lens_type: :wide_angle,  clarity: 0.9)
      engine.create_lens(lens_type: :polarized,   clarity: 0.3)
      result = engine.clearest_lenses(limit: 2)
      expect(result.first[:clarity]).to be >= result.last[:clarity]
    end

    it 'respects the limit' do
      5.times { engine.create_lens(lens_type: :magnifying) }
      expect(engine.clearest_lenses(limit: 3).size).to eq(3)
    end

    it 'returns empty array when no lenses exist' do
      expect(engine.clearest_lenses).to eq([])
    end
  end

  describe '#most_distorted' do
    it 'returns lenses sorted by distortion descending' do
      engine.create_lens(lens_type: :fish_eye)
      engine.create_lens(lens_type: :polarized)
      result = engine.most_distorted(limit: 2)
      expect(result.first[:distortion]).to be >= result.last[:distortion]
    end

    it 'respects the limit' do
      5.times { engine.create_lens(lens_type: :magnifying) }
      expect(engine.most_distorted(limit: 2).size).to eq(2)
    end
  end

  describe '#lens_report' do
    it 'returns empty report when no lenses exist' do
      report = engine.lens_report
      expect(report[:lens_count]).to eq(0)
      expect(report[:lenses]).to eq([])
    end

    it 'includes lens and stack counts' do
      engine.create_lens(lens_type: :magnifying)
      report = engine.lens_report
      expect(report[:lens_count]).to eq(1)
      expect(report[:stack_count]).to eq(0)
    end

    it 'includes avg_clarity and avg_distortion' do
      engine.create_lens(lens_type: :magnifying, clarity: 0.8)
      report = engine.lens_report
      expect(report[:avg_clarity]).to be_a(Float)
      expect(report[:avg_distortion]).to be_a(Float)
    end

    it 'counts sharp and blurry lenses' do
      engine.create_lens(lens_type: :magnifying, clarity: 0.9)
      engine.create_lens(lens_type: :wide_angle, clarity: 0.2)
      report = engine.lens_report
      expect(report[:sharp_count]).to eq(1)
      expect(report[:blurry_count]).to eq(1)
    end
  end
end
