# frozen_string_literal: true

describe Grape::Validations::Validators::LengthValidator do
  let_it_be(:app) do
    Class.new(Grape::API) do
      params do
        requires :list, length: { min: 2, max: 3 }
      end
      post 'with_min_max' do
      end

      params do
        requires :list, type: [Integer], length: { min: 2 }
      end
      post 'with_min_only' do
      end

      params do
        requires :list, type: [Integer], length: { max: 3 }
      end
      post 'with_max_only' do
      end

      params do
        requires :list, type: Integer, length: { max: 3 }
      end
      post 'type_is_not_array' do
      end

      params do
        requires :list, type: [Integer], length: { min: 15, max: 3 }
      end
      post 'min_greater_than_max' do
      end

      params do
        requires :list, type: [Integer], length: { min: 3, max: 3 }
      end
      post 'min_equal_to_max' do
      end

      params do
        requires :list, type: [Integer], length: { min: 0 }
      end
      post 'zero_min' do
      end

      params do
        requires :list, type: [Integer], length: { max: 0 }
      end
      post 'zero_max' do
      end

      params do
        requires :list, type: [Integer], length: { min: 2, message: 'not match' }
      end
      post '/custom-message' do
      end
    end
  end

  describe '/with_min_max' do
    context 'when length is within limits' do
      it do
        post '/with_min_max', list: [1, 2]
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when length is exceeded' do
      it do
        post '/with_min_max', list: [1, 2, 3, 4, 5]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length within 2 and 3')
      end
    end

    context 'when length is less than minimum' do
      it do
        post '/with_min_max', list: [1]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length within 2 and 3')
      end
    end
  end

  describe '/with_max_only' do
    context 'when length is less than limits' do
      it do
        post '/with_max_only', list: [1, 2]
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when length is exceeded' do
      it do
        post '/with_max_only', list: [1, 2, 3, 4, 5]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length less than or equal to 3')
      end
    end
  end

  describe '/with_min_only' do
    context 'when length is greater than limit' do
      it do
        post '/with_min_only', list: [1, 2]
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when length is less than limit' do
      it do
        post '/with_min_only', list: [1]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length greater than or equal to 2')
      end
    end
  end

  describe '/zero_min' do
    context 'when length is equal to the limit' do
      it do
        post '/zero_min', list: []
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when length is greater than limit' do
      it do
        post '/zero_min', list: [1]
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end
  end

  describe '/zero_max' do
    context 'when length is within the limit' do
      it do
        post '/zero_max', list: []
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when length is greater than limit' do
      it do
        post '/zero_max', list: [1]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length less than or equal to 0')
      end
    end
  end

  describe '/type_is_not_array' do
    context 'is no op' do
      it do
        post 'type_is_not_array', list: 12
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end
  end

  describe '/min_greater_than_max' do
    context 'raises an error' do
      it do
        expect { post 'min_greater_than_max', list: [1, 2] }.to raise_error(ArgumentError, 'min 15 cannot be greater than max 3')
      end
    end
  end

  describe '/min_equal_to_max' do
    context 'when array meets expectations' do
      it do
        post 'min_equal_to_max', list: [1, 2, 3]
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when array is less than min' do
      it do
        post 'min_equal_to_max', list: [1, 2]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length within 3 and 3')
      end
    end

    context 'when array is greater than max' do
      it do
        post 'min_equal_to_max', list: [1, 2, 3, 4]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length within 3 and 3')
      end
    end
  end

  describe '/custom-message' do
    context 'is within limits' do
      it do
        post '/custom-message', list: [1, 2, 3]
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'is outside limit' do
      it do
        post '/custom-message', list: [1]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list not match')
      end
    end
  end
end
