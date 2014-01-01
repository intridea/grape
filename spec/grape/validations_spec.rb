require 'spec_helper'

describe Grape::Validations do

  subject { Class.new(Grape::API) }

  def app
    subject
  end

  describe 'params' do
    context 'optional' do
      it 'validates when params is present' do
        subject.params do
          optional :a_number, regexp: /^[0-9]+$/
        end
        subject.get '/optional' do
          'optional works!'
        end

        get '/optional', a_number: 'string'
        last_response.status.should == 400
        last_response.body.should == 'a_number is invalid'

        get '/optional', a_number: 45
        last_response.status.should == 200
        last_response.body.should == 'optional works!'
      end

      it "doesn't validate when param not present" do
        subject.params do
          optional :a_number, regexp: /^[0-9]+$/
        end
        subject.get '/optional' do
          'optional works!'
        end

        get '/optional'
        last_response.status.should == 200
        last_response.body.should == 'optional works!'
      end

      it 'adds to declared parameters' do
        subject.params do
          optional :some_param
        end
        subject.settings[:declared_params].should == [:some_param]
      end
    end

    context 'required' do
      before do
        subject.params do
          requires :key
        end
        subject.get '/required' do
          'required works'
        end
      end

      it 'errors when param not present' do
        get '/required'
        last_response.status.should == 400
        last_response.body.should == 'key is missing'
      end

      it "doesn't throw a missing param when param is present" do
        get '/required', key: 'cool'
        last_response.status.should == 200
        last_response.body.should == 'required works'
      end

      it 'adds to declared parameters' do
        subject.params do
          requires :some_param
        end
        subject.settings[:declared_params].should == [:some_param]
      end
    end

    context 'required with an Array block' do
      before do
        subject.params do
          requires :items, type: Array do
            requires :key
          end
        end
        subject.get '/required' do
          'required works'
        end
      end

      it 'errors when param not present' do
        get '/required'
        last_response.status.should == 400
        last_response.body.should == 'items is missing'
      end

      it "errors when param is not an Array" do
        get '/required', items: "hello"
        last_response.status.should == 400
        last_response.body.should == 'items is invalid, items[key] is missing'

        get '/required', items: { :key => 'foo' }
        last_response.status.should == 400
        last_response.body.should == 'items is invalid'
      end

      it "doesn't throw a missing param when param is present" do
        get '/required', items: [{key: 'hello'}, {key: 'world'}]
        last_response.status.should == 200
        last_response.body.should == 'required works'
      end

      it "doesn't allow any key in the options hash other than type" do
        expect {
          subject.params do
            requires(:items, desc: 'Foo') do
              requires :key
            end
          end
        }.to raise_error ArgumentError
      end

      it 'adds to declared parameters' do
        subject.params do
          requires :items do
            requires :key
          end
        end
        subject.settings[:declared_params].should == [items: [:key]]
      end
    end

    context 'required with a Hash block' do
      before do
        subject.params do
          requires :items, type: Hash do
            requires :key
          end
        end
        subject.get '/required' do
          'required works'
        end
      end

      it 'errors when param not present' do
        get '/required'
        last_response.status.should == 400
        last_response.body.should == 'items is missing, items[key] is missing'
      end

      it "errors when param is not a Hash" do
        get '/required', items: "hello"
        last_response.status.should == 400
        last_response.body.should == 'items is invalid, items[key] is missing'

        get '/required', items: [{ :key => 'foo' }]
        last_response.status.should == 400
        last_response.body.should == 'items is invalid'
      end

      it "doesn't throw a missing param when param is present" do
        get '/required', items: {key: 'hello'}
        last_response.status.should == 200
        last_response.body.should == 'required works'
      end

      it "doesn't allow any key in the options hash other than type" do
        expect {
          subject.params do
            requires(:items, desc: 'Foo') do
              requires :key
            end
          end
        }.to raise_error ArgumentError
      end

      it 'adds to declared parameters' do
        subject.params do
          requires :items do
            requires :key
          end
        end
        subject.settings[:declared_params].should == [items: [:key]]
      end
    end

    context 'group' do
      before do
        subject.params do
          group :items do
            requires :key
          end
        end
        subject.get '/required' do
          'required works'
        end
      end

      it 'errors when param not present' do
        get '/required'
        last_response.status.should == 400
        last_response.body.should == 'items is missing'
      end

      it "doesn't throw a missing param when param is present" do
        get '/required', items: [key: 'hello', key: 'world']
        last_response.status.should == 200
        last_response.body.should == 'required works'
      end

      it 'adds to declared parameters' do
        subject.params do
          group :items do
            requires :key
          end
        end
        subject.settings[:declared_params].should == [items: [:key]]
      end
    end

    context 'validation within arrays' do
      before do
        subject.params do
          group :children do
            requires :name
            group :parents do
              requires :name
            end
          end
        end
        subject.get '/within_array' do
          'within array works'
        end
      end

      it 'can handle new scopes within child elements' do
        get '/within_array', children: [
          { name: 'John', parents: [{ name: 'Jane' }, { name: 'Bob'}] },
          { name: 'Joe', parents: [{ name: 'Josie' }] }
        ]
        last_response.status.should == 200
        last_response.body.should == 'within array works'
      end

      it 'errors when a parameter is not present' do
        get '/within_array', children: [
          { name: 'Jim', parents: [{}] },
          { name: 'Job', parents: [{ name: 'Joy' }] }
        ]
        # XXX: with body parameters in json or XML or similar this
        # should actually fail with: children[parents][name] is missing.
        last_response.status.should == 400
        last_response.body.should == 'children[parents] is missing'
      end

      it 'safely handles empty arrays and blank parameters' do
        # XXX: with body parameters in json or XML or similar this
        # should actually return 200, since an empty array is valid.
        get '/within_array', children: []
        last_response.status.should == 400
        last_response.body.should == 'children is missing'
        get '/within_array', children: [name: 'Jay']
        last_response.status.should == 400
        last_response.body.should == 'children[parents] is missing'
      end

      it "errors when param is not an Array" do
        # XXX: would be nicer if these just returned 'children is invalid'
        get '/within_array', children: "hello"
        last_response.status.should == 400
        last_response.body.should == 'children is invalid, children[name] is missing, children[parents] is missing, children[parents] is invalid, children[parents][name] is missing'

        get '/within_array', children: { :name => 'foo' }
        last_response.status.should == 400
        last_response.body.should == 'children is invalid, children[parents] is missing'

        get '/within_array', children: [name: 'Jay', parents: { name: 'Fred'}]
        last_response.status.should == 400
        last_response.body.should == 'children[parents] is invalid'
      end
    end

    context 'validation within arrays with JSON' do
      before do
        subject.params do
          group :children do
            requires :name
            group :parents do
              requires :name
            end
          end
        end
        subject.put '/within_array' do
          'within array works'
        end
      end

      it 'can handle new scopes within child elements' do
        put_with_json '/within_array', children: [
          { name: 'John', parents: [{ name: 'Jane' }, { name: 'Bob'}] },
          { name: 'Joe', parents: [{ name: 'Josie' }] }
        ]
        last_response.status.should == 200
        last_response.body.should == 'within array works'
      end

      it 'errors when a parameter is not present' do
        put_with_json '/within_array', children: [
          { name: 'Jim', parents: [{}] },
          { name: 'Job', parents: [{ name: 'Joy' }] }
        ]
        last_response.status.should == 400
        last_response.body.should == 'children[parents][name] is missing'
      end

      it 'safely handles empty arrays and blank parameters' do
        put_with_json '/within_array', children: []
        last_response.status.should == 200
        put_with_json '/within_array', children: [name: 'Jay']
        last_response.status.should == 400
        last_response.body.should == 'children[parents] is missing'
      end
    end

    context 'optional with an Array block' do
      before do
        subject.params do
          optional :items, type: Array do
            requires :key
          end
        end
        subject.get '/optional_group' do
          'optional group works'
        end
      end

      it "doesn't throw a missing param when the group isn't present" do
        get '/optional_group'
        last_response.status.should == 200
        last_response.body.should == 'optional group works'
      end

      it "doesn't throw a missing param when both group and param are given" do
        get '/optional_group', items: [{ key: 'foo' }]
        last_response.status.should == 200
        last_response.body.should == 'optional group works'
      end

      it "errors when group is present, but required param is not" do
        get '/optional_group', items: [{ not_key: 'foo' }]
        last_response.status.should == 400
        last_response.body.should == 'items[key] is missing'
      end

      it "errors when param is present but isn't an Array" do
        get '/optional_group', items: "hello"
        last_response.status.should == 400
        last_response.body.should == 'items is invalid, items[key] is missing'

        get '/optional_group', items: { :key => 'foo' }
        last_response.status.should == 400
        last_response.body.should == 'items is invalid'
      end

      it 'adds to declared parameters' do
        subject.params do
          optional :items do
            requires :key
          end
        end
        subject.settings[:declared_params].should == [items: [:key]]
      end
    end

    context 'nested optional Array blocks' do
      before do
        subject.params do
          optional :items, type: Array do
            requires :key
            optional(:optional_subitems, type: Array) { requires :value }
            requires(:required_subitems, type: Array) { requires :value }
          end
        end
        subject.get('/nested_optional_group') { 'nested optional group works' }
      end

      it 'does no internal validations if the outer group is blank' do
        get '/nested_optional_group'
        last_response.status.should == 200
        last_response.body.should == 'nested optional group works'
      end

      it 'does internal validations if the outer group is present' do
        get '/nested_optional_group', items: [{ key: 'foo' }]
        last_response.status.should == 400
        last_response.body.should == 'items[required_subitems] is missing'

        get '/nested_optional_group', items: [{ key: 'foo', required_subitems: [{ value: 'bar' }] }]
        last_response.status.should == 200
        last_response.body.should == 'nested optional group works'
      end

      it 'handles deep nesting' do
        get '/nested_optional_group', items: [{ key: 'foo', required_subitems: [{ value: 'bar' }], optional_subitems: [{ not_value: 'baz' }] }]
        last_response.status.should == 400
        last_response.body.should == 'items[optional_subitems][value] is missing'

        get '/nested_optional_group', items: [{ key: 'foo', required_subitems: [{ value: 'bar' }], optional_subitems: [{ value: 'baz' }] }]
        last_response.status.should == 200
        last_response.body.should == 'nested optional group works'
      end

      it 'handles validation within arrays' do
        get '/nested_optional_group', items: [{key: 'foo'}]
        last_response.status.should == 400
        last_response.body.should == 'items[required_subitems] is missing'

        get '/nested_optional_group', items: [{key: 'foo', required_subitems: [{ value: 'bar' }]}]
        last_response.status.should == 200
        last_response.body.should == 'nested optional group works'

        get '/nested_optional_group', items: [{key: 'foo', required_subitems: [{ value: 'bar' }], optional_subitems: [{ not_value: 'baz' }]}]
        last_response.status.should == 400
        last_response.body.should == 'items[optional_subitems][value] is missing'
      end

      it 'adds to declared parameters' do
        subject.params do
          optional :items do
            requires :key
            optional(:optional_subitems) { requires :value }
            requires(:required_subitems) { requires :value }
          end
        end
        subject.settings[:declared_params].should == [items: [:key, { optional_subitems: [:value] }, { required_subitems: [:value] }]]
      end
    end

    context 'multiple validation errors' do
      before do
        subject.params do
          requires :yolo
          requires :swag
        end
        subject.get '/two_required' do
          'two required works'
        end
      end

      it 'throws the validation errors' do
        get '/two_required'
        last_response.status.should == 400
        last_response.body.should =~ /yolo is missing/
        last_response.body.should =~ /swag is missing/
      end
    end

    context 'custom validation' do
      module CustomValidations
        class Customvalidator < Grape::Validations::Validator
          def validate_param!(attr_name, params)
            unless params[attr_name] == 'im custom'
              raise Grape::Exceptions::Validation, param: @scope.full_name(attr_name), message: "is not custom!"
            end
          end
        end
      end

      context 'when using optional with a custom validator' do
        before do
          subject.params do
            optional :custom, customvalidator: true
          end
          subject.get '/optional_custom' do
            'optional with custom works!'
          end
        end

        it 'validates when param is present' do
          get '/optional_custom', custom: 'im custom'
          last_response.status.should == 200
          last_response.body.should == 'optional with custom works!'

          get '/optional_custom', custom: 'im wrong'
          last_response.status.should == 400
          last_response.body.should == 'custom is not custom!'
        end

        it "skips validation when parameter isn't present" do
          get '/optional_custom'
          last_response.status.should == 200
          last_response.body.should == 'optional with custom works!'
        end

        it 'validates with custom validator when param present and incorrect type' do
          subject.params do
            optional :custom, type: String, customvalidator: true
          end

          get '/optional_custom', custom: 123
          last_response.status.should == 400
          last_response.body.should == 'custom is not custom!'
        end
      end

      context 'when using requires with a custom validator' do
        before do
          subject.params do
            requires :custom, customvalidator: true
          end
          subject.get '/required_custom' do
            'required with custom works!'
          end
        end

        it 'validates when param is present' do
          get '/required_custom', custom: 'im wrong, validate me'
          last_response.status.should == 400
          last_response.body.should == 'custom is not custom!'

          get '/required_custom', custom: 'im custom'
          last_response.status.should == 200
          last_response.body.should == 'required with custom works!'
        end

        it 'validates when param is not present' do
          get '/required_custom'
          last_response.status.should == 400
          last_response.body.should == 'custom is missing, custom is not custom!'
        end

        context 'nested namespaces' do
          before do
            subject.params do
              requires :custom, customvalidator: true
            end
            subject.namespace 'nested' do
              get 'one' do
                'validation failed'
              end
              namespace 'nested' do
                get 'two' do
                  'validation failed'
                end
              end
            end
            subject.namespace 'peer' do
              get 'one' do
                'no validation required'
              end
              namespace 'nested' do
                get 'two' do
                  'no validation required'
                end
              end
            end

            subject.namespace 'unrelated' do
              params do
                requires :name
              end
              get 'one' do
                'validation required'
              end

              namespace 'double' do
                get 'two' do
                  'no validation required'
                end
              end
            end
          end

          specify 'the parent namespace uses the validator' do
            get '/nested/one', custom: 'im wrong, validate me'
            last_response.status.should == 400
            last_response.body.should == 'custom is not custom!'
          end

          specify 'the nested namesapce inherits the custom validator' do
            get '/nested/nested/two', custom: 'im wrong, validate me'
            last_response.status.should == 400
            last_response.body.should == 'custom is not custom!'
          end

          specify 'peer namesapces does not have the validator' do
            get '/peer/one', custom: 'im not validated'
            last_response.status.should == 200
            last_response.body.should == 'no validation required'
          end

          specify 'namespaces nested in peers should also not have the validator' do
            get '/peer/nested/two', custom: 'im not validated'
            last_response.status.should == 200
            last_response.body.should == 'no validation required'
          end

          specify 'when nested, specifying a route should clear out the validations for deeper nested params' do
            get '/unrelated/one'
            last_response.status.should == 400
            get '/unrelated/double/two'
            last_response.status.should == 200
          end
        end
      end
    end # end custom validation
  end
end
