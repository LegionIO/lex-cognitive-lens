# frozen_string_literal: true

require 'legion/extensions/cognitive_lens/client'

RSpec.describe Legion::Extensions::CognitiveLens::Client do
  let(:client) { described_class.new }

  it 'responds to runner methods' do
    expect(client).to respond_to(:create_lens)
    expect(client).to respond_to(:stack_lenses)
    expect(client).to respond_to(:view_through_stack)
    expect(client).to respond_to(:degrade_all)
    expect(client).to respond_to(:lens_report)
    expect(client).to respond_to(:clearest_lenses)
    expect(client).to respond_to(:most_distorted)
  end

  it 'maintains isolated engine state per instance' do
    client2 = described_class.new
    client.create_lens(lens_type: :magnifying)
    expect(client.lens_report[:lens_count]).to eq(1)
    expect(client2.lens_report[:lens_count]).to eq(0)
  end

  it 'round-trips a full lens lifecycle' do
    # Create two lenses
    l1 = client.create_lens(lens_type: :magnifying, clarity: 0.9)
    l2 = client.create_lens(lens_type: :wide_angle, clarity: 0.8)
    expect(l1[:success]).to be true
    expect(l2[:success]).to be true

    # Stack them
    stack_result = client.stack_lenses(lens_ids: [l1[:lens][:id], l2[:lens][:id]])
    expect(stack_result[:success]).to be true

    # View through the stack
    view = client.view_through_stack(stack_id: stack_result[:stack_id], content: 0.7)
    expect(view[:success]).to be true
    expect(view[:perceived]).to be_between(0.0, 1.0)

    # Degrade and verify report
    client.degrade_all(rate: 0.05)
    report = client.lens_report
    expect(report[:lens_count]).to eq(2)
    expect(report[:avg_clarity]).to be < 0.9
  end

  it 'creates all 6 lens types without error' do
    lens_types = Legion::Extensions::CognitiveLens::Helpers::Constants::LENS_TYPES
    results = lens_types.map { |lt| client.create_lens(lens_type: lt) }
    expect(results.all? { |r| r[:success] }).to be true
  end

  it 'reports clearest and most distorted after creating lenses' do
    client.create_lens(lens_type: :fish_eye)
    client.create_lens(lens_type: :polarized)

    clearest = client.clearest_lenses(limit: 1)
    distorted = client.most_distorted(limit: 1)

    expect(clearest[:lenses].size).to eq(1)
    expect(distorted[:lenses].size).to eq(1)
  end
end
