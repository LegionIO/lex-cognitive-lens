# frozen_string_literal: true

require 'legion/extensions/cognitive_lens/client'

RSpec.describe Legion::Extensions::CognitiveLens::Runners::CognitiveLens do
  let(:client) { Legion::Extensions::CognitiveLens::Client.new }
  let(:engine) { Legion::Extensions::CognitiveLens::Helpers::LensEngine.new }

  describe '#create_lens' do
    it 'returns success: true' do
      result = client.create_lens(lens_type: :magnifying)
      expect(result[:success]).to be true
    end

    it 'returns lens hash' do
      result = client.create_lens(lens_type: :magnifying)
      expect(result[:lens]).to include(:id, :lens_type, :magnification)
    end

    it 'creates all supported lens types' do
      lens_types = Legion::Extensions::CognitiveLens::Helpers::Constants::LENS_TYPES
      lens_types.each do |lt|
        result = client.create_lens(lens_type: lt)
        expect(result[:success]).to be true
      end
    end

    it 'returns success: false for invalid lens type' do
      result = client.create_lens(lens_type: :quantum)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/unknown lens_type/)
    end

    it 'forwards custom magnification' do
      result = client.create_lens(lens_type: :magnifying, magnification: 3.0)
      expect(result[:lens][:magnification]).to be_within(0.001).of(3.0)
    end

    it 'forwards custom clarity' do
      result = client.create_lens(lens_type: :magnifying, clarity: 0.7)
      expect(result[:lens][:clarity]).to be_within(0.001).of(0.7)
    end

    it 'accepts injected engine' do
      result = client.create_lens(lens_type: :wide_angle, engine: engine)
      expect(result[:success]).to be true
      expect(engine.lenses.size).to eq(1)
    end
  end

  describe '#stack_lenses' do
    let(:lens1_result) { client.create_lens(lens_type: :magnifying) }
    let(:lens2_result) { client.create_lens(lens_type: :wide_angle) }
    let(:lens1_id) { lens1_result[:lens][:id] }
    let(:lens2_id) { lens2_result[:lens][:id] }

    it 'returns success: true' do
      result = client.stack_lenses(lens_ids: [lens1_id, lens2_id])
      expect(result[:success]).to be true
    end

    it 'returns a stack_id' do
      result = client.stack_lenses(lens_ids: [lens1_id])
      expect(result[:stack_id]).to be_a(String)
    end

    it 'returns stack details' do
      result = client.stack_lenses(lens_ids: [lens1_id])
      expect(result[:stack]).to include(:lens_count, :combined_magnification)
    end

    it 'returns success: false for unknown lens ids' do
      result = client.stack_lenses(lens_ids: ['unknown'])
      expect(result[:success]).to be false
    end

    it 'returns success: false when lens_ids is not an array' do
      result = client.stack_lenses(lens_ids: 'bad')
      expect(result[:success]).to be false
    end
  end

  describe '#view_through_stack' do
    let(:lens_id) do
      client.create_lens(lens_type: :magnifying)[:lens][:id]
    end
    let(:stack_id) do
      client.stack_lenses(lens_ids: [lens_id])[:stack_id]
    end

    it 'returns success: true' do
      result = client.view_through_stack(stack_id: stack_id, content: 0.6)
      expect(result[:success]).to be true
    end

    it 'returns perceived value' do
      result = client.view_through_stack(stack_id: stack_id, content: 0.6)
      expect(result[:perceived]).to be_between(0.0, 1.0)
    end

    it 'returns success: false for unknown stack_id' do
      result = client.view_through_stack(stack_id: 'bad', content: 0.5)
      expect(result[:success]).to be false
    end
  end

  describe '#degrade_all' do
    it 'returns success: true' do
      result = client.degrade_all
      expect(result[:success]).to be true
    end

    it 'reports number of degraded lenses' do
      client.create_lens(lens_type: :magnifying)
      client.create_lens(lens_type: :wide_angle)
      result = client.degrade_all
      expect(result[:degraded]).to eq(2)
    end

    it 'accepts custom rate' do
      result = client.degrade_all(rate: 0.1)
      expect(result[:rate]).to eq(0.1)
    end
  end

  describe '#lens_report' do
    it 'returns success: true' do
      result = client.lens_report
      expect(result[:success]).to be true
    end

    it 'includes lens_count' do
      result = client.lens_report
      expect(result).to have_key(:lens_count)
    end

    it 'counts created lenses' do
      client.create_lens(lens_type: :magnifying)
      client.create_lens(lens_type: :polarized)
      result = client.lens_report
      expect(result[:lens_count]).to eq(2)
    end
  end

  describe '#clearest_lenses' do
    it 'returns success: true' do
      result = client.clearest_lenses
      expect(result[:success]).to be true
    end

    it 'returns lenses array' do
      client.create_lens(lens_type: :magnifying, clarity: 0.9)
      result = client.clearest_lenses
      expect(result[:lenses]).to be_an(Array)
    end

    it 'respects limit' do
      5.times { client.create_lens(lens_type: :magnifying) }
      result = client.clearest_lenses(limit: 2)
      expect(result[:lenses].size).to be <= 2
    end
  end

  describe '#most_distorted' do
    it 'returns success: true' do
      result = client.most_distorted
      expect(result[:success]).to be true
    end

    it 'returns lenses array' do
      client.create_lens(lens_type: :fish_eye)
      result = client.most_distorted
      expect(result[:lenses]).to be_an(Array)
    end

    it 'respects limit' do
      5.times { client.create_lens(lens_type: :fish_eye) }
      result = client.most_distorted(limit: 2)
      expect(result[:lenses].size).to be <= 2
    end
  end
end
