# encoding: utf-8

require 'logger'
require 'socket'
require 'active_support/core_ext/object'
require 'active_support/json/encoding'

require 'rollbar/item'
begin
  require 'rollbar/delay/sidekiq'
  require 'rollbar/delay/sucker_punch'
rescue LoadError
end

begin
  require 'sucker_punch'
  require 'sucker_punch/testing/inline'
rescue LoadError
end

require 'spec_helper'

describe Rollbar do
  let(:notifier) { Rollbar.notifier }

  before do
    Rollbar.clear_notifier!
    configure
  end

  shared_examples 'stores the root notifier' do

  end

  # Backwards
  context 'report_message' do
    before(:each) do
      configure
      Rollbar.configure do |config|
        config.logger = logger_mock
      end
    end

    let(:logger_mock) { double("Rails.logger").as_null_object }
    let(:user) { User.create(:email => 'email@example.com', :encrypted_password => '', :created_at => Time.now, :updated_at => Time.now) }

    it 'should be able to report form validation errors when they are present' do
      logger_mock.should_receive(:info).with('[Rollbar] Success')
      user.errors.add(:example, "error")
      user.report_validation_errors_to_rollbar
    end

    it 'should not report form validation errors when they are not present' do
      logger_mock.should_not_receive(:info).with('[Rollbar] Success')
      user.errors.clear
      user.report_validation_errors_to_rollbar
    end
  end

  # configure with some basic params
  def configure
    reconfigure_notifier
  end
end
