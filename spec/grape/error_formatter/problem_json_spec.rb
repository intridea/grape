# frozen_string_literal: true

describe Grape::ErrorFormatter::ProblemJson do
  subject(:problem) { JSON.parse(last_response.body) }

  let(:app) do
    Class.new(Grape::API) do
      format :json
      error_formatter :json, Grape::ErrorFormatter::ProblemJson

      get(:message) { error!('Your balance is 30, but that costs 50.', 403) }
      get(:members) do
        error!({ type: 'https://example.com/probs/out-of-credit', title: 'You do not have enough credit.',
                 'status' => 200, instance: '/account/12345/msgs/abc', balance: 30 }, 403)
      end
      get(:no_message) { error!(nil, 404) }
      get(:unnamed_status) { error!('Client closed the request', 499) }
      get(:content_type) { error!('nope', 400, 'Content-Type' => 'application/json') }
      get(:thrown) { throw :error, status: :gone, message: 'Gone for good' }

      params { requires :id, type: Integer }
      get(:validated) { 'ok' }
    end
  end

  it 'answers with the message as the detail of an about:blank problem' do
    get '/message'
    expect(last_response.status).to eq(403)
    expect(last_response.content_type).to eq('application/problem+json')
    expect(problem).to eq('type' => 'about:blank', 'title' => 'Forbidden', 'status' => 403, 'detail' => 'Your balance is 30, but that costs 50.')
  end

  it 'keeps the members a Hash brings, with the status of the response' do
    get '/members'
    expect(problem).to eq(
      'type' => 'https://example.com/probs/out-of-credit', 'title' => 'You do not have enough credit.',
      'status' => 403, 'instance' => '/account/12345/msgs/abc', 'balance' => 30
    )
  end

  it 'leaves the detail out when there is no message' do
    get '/no_message'
    expect(problem).to eq('type' => 'about:blank', 'title' => 'Not Found', 'status' => 404)
  end

  it 'leaves the title out for a status with no phrase' do
    get '/unnamed_status'
    expect(problem).to eq('type' => 'about:blank', 'status' => 499, 'detail' => 'Client closed the request')
  end

  it 'answers a thrown Symbol status with its code and phrase' do
    get '/thrown'
    expect(last_response.status).to eq(410)
    expect(problem).to eq('type' => 'about:blank', 'title' => 'Gone', 'status' => 410, 'detail' => 'Gone for good')
  end

  it 'lets a Content-Type the error carries win' do
    get '/content_type'
    expect(last_response.content_type).to eq('application/json')
  end

  it 'lists the parameters of a validation failure under errors' do
    get '/validated', id: 'x'
    expect(last_response.content_type).to eq('application/problem+json')
    expect(problem).to eq(
      'type' => 'about:blank', 'title' => 'Bad Request', 'status' => 400, 'detail' => 'id is invalid',
      'errors' => [{ 'params' => ['id'], 'messages' => ['is invalid'] }]
    )
  end

  context 'when a rescue_from hands the validation failure to error!' do
    let(:app) do
      Class.new(Grape::API) do
        format :json
        error_formatter :json, Grape::ErrorFormatter::ProblemJson
        rescue_from(Grape::Exceptions::ValidationErrors) do |e|
          next error!(e, 422) unless params[:own]

          error!({ detail: 'Invalid order', errors: e.full_messages }, 422, {}, nil, e)
        end

        params do
          requires :id, type: Integer
          optional :own
        end
        get(:validated) { 'ok' }
      end
    end

    it 'lists its parameters under errors' do
      get '/validated'
      expect(problem).to include('status' => 422, 'detail' => 'id is missing', 'errors' => [{ 'params' => ['id'], 'messages' => ['is missing'] }])
    end

    it 'keeps errors the message brings' do
      get '/validated', own: 1
      expect(problem).to include('detail' => 'Invalid order', 'errors' => ['id is missing'])
    end
  end

  context 'when rescue_from asks for the backtrace and the original exception' do
    let(:app) do
      Class.new(Grape::API) do
        format :json
        error_formatter :json, Grape::ErrorFormatter::ProblemJson
        rescue_from :all, backtrace: true, original_exception: true

        get(:boom) { raise ArgumentError, 'boom' }
      end
    end

    it 'adds them as extension members' do
      get '/boom'
      expect(problem).to include('status' => 500, 'detail' => 'boom', 'original_exception' => '#<ArgumentError: boom>')
      expect(problem['backtrace']).to be_an(Array).and(be_present)
    end
  end

  context 'when the error cannot be rendered' do
    let(:app) do
      Class.new(Grape::API) do
        format :json
        error_formatter :json, Grape::ErrorFormatter::ProblemJson
        rescue_from(:all) { |e| error!({ detail: e.message }, 404) }

        # A message JSON cannot serialize.
        get('/') { raise StandardError, +"bad \xC3 byte".b }
      end
    end

    it 'answers with the framework problem' do
      get '/'
      expect(last_response.status).to eq(500)
      expect(last_response.content_type).to eq('application/problem+json')
      expect(problem).to eq('type' => 'about:blank', 'title' => 'Internal Server Error', 'status' => 500, 'detail' => 'Internal Server Error')
    end
  end
end
