require 'spec_helper'
describe 'restful' do

  context 'with defaults for all parameters' do
    it { should contain_class('restful') }
  end
end
