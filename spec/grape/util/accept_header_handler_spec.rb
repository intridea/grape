# frozen_string_literal: true

require 'grape/util/accept_header_handler'

RSpec.describe Grape::Util::AcceptHeaderHandler do
  let(:instance) do
    described_class.new(
      accept_header: accept_header,
      versions: versions,
      **options
    )
  end

  subject { instance.match_best_quality_media_type! }

  let(:accept_header) { '*/*' }
  let(:versions) { ['v1'] }
  let(:options) { {} }

  describe '#match_best_quality_media_type!' do
    context 'when no vendor set' do
      let(:options) do
        {
          vendor: nil,
        }
      end

      it { is_expected.to be_nil }
    end

    context 'when strict header check' do
      let(:options) do
        {
          vendor: 'vendor',
          strict: true
        }
      end

      context 'when accept_header blank' do
        let(:accept_header) { nil }

        before do
          allow(Grape::Exceptions::InvalidAcceptHeader).to receive(:new)
              .with('Accept header must be set.', { Grape::Http::Headers::X_CASCADE => 'pass' })
              .and_call_original
        end

        it 'raises a Grape::Exceptions::InvalidAcceptHeader' do
          expect { subject }.to raise_error(Grape::Exceptions::InvalidAcceptHeader)
        end
      end

      context 'when vendor not found' do
        let(:accept_header) { '*/*'}

        before do
          allow(Grape::Exceptions::InvalidAcceptHeader).to receive(:new)
            .with('API vendor or version not found.', { Grape::Http::Headers::X_CASCADE => 'pass' })
            .and_call_original
        end

        it 'raises a Grape::Exceptions::InvalidAcceptHeader' do
          expect { subject }.to raise_error(Grape::Exceptions::InvalidAcceptHeader)
        end
      end
    end

    context 'when media_type found' do
      let(:options) do
        {
          vendor: 'vendor',
        }
      end

      let(:accept_header) { 'application/vnd.vendor-v1+json' }

      it 'yields a media type' do
        expect { |b| instance.match_best_quality_media_type!(&b) }.to yield_with_args(Grape::Util::MediaType.new(type: 'application', subtype: 'vnd.vendor-v1+json'))
      end
    end

    context 'when media_type is not found' do
      let(:options) do
        {
          vendor: 'vendor',
        }
      end

      let(:accept_header) { 'application/vnd.another_vendor-v1+json' }

      context 'when allowed_methods present' do
        let(:allowed_methods) { ['OPTIONS'] }

        subject { instance.match_best_quality_media_type!(allowed_methods: allowed_methods) }

        it { is_expected.to match_array(allowed_methods) }
      end

      context 'when vendor not found' do
        before do
          allow(Grape::Exceptions::InvalidAcceptHeader).to receive(:new)
                                                             .with('API vendor not found.', { Grape::Http::Headers::X_CASCADE => 'pass' })
                                                             .and_call_original
        end

        it 'raises a Grape::Exceptions::InvalidAcceptHeader' do
          expect { subject }.to raise_error(Grape::Exceptions::InvalidAcceptHeader)
        end
      end

      context 'when version not found' do
        let(:versions) { ['v2'] }
        let(:accept_header) { 'application/vnd.vendor-v1+json' }

        before do
          allow(Grape::Exceptions::InvalidVersionHeader).to receive(:new)
                                                             .with('API version not found.', { Grape::Http::Headers::X_CASCADE => 'pass' })
                                                             .and_call_original
        end

        it 'raises a Grape::Exceptions::InvalidAcceptHeader' do
          expect { subject }.to raise_error(Grape::Exceptions::InvalidVersionHeader)
        end
      end
    end
  end
end
