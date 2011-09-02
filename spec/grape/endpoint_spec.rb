require 'spec_helper'

describe Grape::Endpoint do
  subject { Class.new(Grape::API) }
  before { subject.default_format :txt }
  def app; subject end
  
  describe '#status' do
    it 'should be callable from within a block' do
      subject.get('/home') do
        status 206
        "Hello"
      end
      
      get '/home'
      last_response.status.should == 206
      last_response.body.should == "Hello"
    end
  end
  
  describe '#header' do
    it 'should be callable from within a block' do
      subject.get('/hey') do
        header 'X-Awesome', 'true'
        "Awesome"
      end
      
      get '/hey'
      last_response.headers['X-Awesome'].should == 'true'
    end
  end
  
  describe '#params' do
    it 'should be available to the caller' do
      subject.get('/hey') do
        params[:howdy]
      end
      
      get '/hey?howdy=hey'
      last_response.body.should == 'hey'
    end
    
    it 'should parse from path segments' do
      subject.get('/hey/:id') do
        params[:id]
      end
      
      get '/hey/12'
      last_response.body.should == '12'
    end

    it 'returns a hashed version of parameters which are hashes with symbol keys' do
      subject.get('/hey') do
        "#{params[:location][:city]}, #{params[:location][:state]}"
      end

      get '/hey?location[city]=New%20York&location[state]=NY'
      last_response.body.should == "New York, NY"
    end

    it 'returns a hashed version of parameters which are hashes with string keys' do
      subject.get('/hey') do
        "#{params['location']['city']}, #{params['location']['state']}"
      end

      get '/hey?location[city]=New%20York&location[state]=NY'
      last_response.body.should == "New York, NY"
    end

    it 'returns a hashed version of parameters which are hashes with symbol keys multiple levels deep' do
      subject.get('/hey') do
        params[:location][:city][:neighborhood]
      end

      get '/hey?location[city][neighborhood]=Chelsea'
      last_response.body.should == "Chelsea"
    end

    it 'returns a hashed version of parameters which are hashes with string keys multiple levels deep' do
      subject.get('/hey') do
        params['location']['city']['neighborhood']
      end

      get '/hey?location[city][neighborhood]=Chelsea'
      last_response.body.should == "Chelsea"
    end
  end
  
  describe '#error!' do
    it 'should accept a message' do
      subject.get('/hey') do
        error! "This is not valid."
        "This is valid."
      end
      
      get '/hey'
      last_response.status.should == 403
      last_response.body.should == "This is not valid."
    end
    
    it 'should accept a code' do
      subject.get('/hey') do
        error! "Unauthorized.", 401
      end
      
      get '/hey'
      last_response.status.should == 401
      last_response.body.should == "Unauthorized."
    end

    it 'should accept an object and render it in format' do
      subject.get '/hey' do
        error!({'dude' => 'rad'}, 403)
      end

      get '/hey.json'
      last_response.status.should == 403
      last_response.body.should == '{"dude":"rad"}'
    end
  end
  
  it 'should not persist params between calls' do
    subject.post('/new') do
      params[:text]
    end
    
    post '/new', :text => 'abc'
    last_response.body.should == 'abc'
    
    post '/new', :text => 'def'
    last_response.body.should == 'def'
  end
  
  it 'should reset all instance variables (except block) between calls' do
    subject.helpers do
      def memoized
        @memoized ||= params[:howdy]
      end
    end
    
    subject.get('/hello') do
      memoized
    end
    
    get '/hello?howdy=hey'
    last_response.body.should == 'hey'
    get '/hello?howdy=yo'
    last_response.body.should == 'yo'
  end

  context 'filters' do
    describe 'before filters' do
      it 'should run the before filter if set' do
        subject.before{ env['before_test'] = "OK" }
        subject.get('/before_test'){ env['before_test'] }

        get '/before_test'
        last_response.body.should == "OK"
      end
    end

    describe 'after filters' do
      it 'should override the response body if it sets it' do
        subject.after{ body "after" }
        subject.get('/after_test'){ "during" }
        get '/after_test'
        last_response.body.should == 'after'
      end

      it 'should not override the response body with its return' do
        subject.after{ "after" }
        subject.get('/after_test'){ "body" }
        get '/after_test'
        last_response.body.should == "body"
      end
    end
  end
end
