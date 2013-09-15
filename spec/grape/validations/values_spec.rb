require 'spec_helper'

describe Grape::Validations::ValuesValidator do

  module ValidationsSpec
    module ValuesValidatorSpec
      class API < Grape::API
        default_format :json

        params do
          requires :type, :values => ['valid-type1', 'valid-type2', 'valid-type3']
        end
        get '/' do
          { :type => params[:type] }
        end

        params do
          optional :type, :values => ['valid-type1', 'valid-type2', 'valid-type3'], :default => 'valid-type2'
        end
        get '/default/valid' do
          { :type => params[:type] }
        end

      end
    end
  end

  def app
    ValidationsSpec::ValuesValidatorSpec::API
  end

  it 'should allow a valid value for a parameter' do
    get("/", :type => 'valid-type1')
    last_response.status.should eq 200
    last_response.body.should eq({ :type => "valid-type1" }.to_json)
  end

  it 'should not allow an invalid value for a parameter' do
    get("/", :type => 'invalid-type')
    last_response.status.should eq 400
    last_response.body.should eq({ :error => "type does not have a valid value" }.to_json)
  end

  it 'should allow a valid default value' do
    get("/default/valid")
    last_response.status.should eq 200
    last_response.body.should eq({ :type => "valid-type2" }.to_json)
  end

end
