# frozen_string_literal: true

require "ostruct"

class BaseService
  extend Forwardable

  def_delegators :@context, :params, :options, :errors

  attr_reader :context, :succeed, :event_emitter

  class << self
    def call(params: {}, options: {}, &block)
      actions = self.new(params:, options:)

      yield actions.event_emitter if block.present?

      begin
        actions.run
      rescue StandardError => e
        Rails.logger.error(e)
        actions.errors << e

        if block.present?
          actions.event_emitter.emit(:failure, actions.context)
        end
      end

      actions
    end
  end

  def initialize(params:, options:)
    @context = ::OpenStruct.new(params:, options:, errors: [])
    @succeed = true
    @event_emitter = EventEmitter.new
  end

  def run
    raise NotImplementedError, "Method not implemented in #{self.class}"
  end

  def broadcast(event, result)
    event_emitter.emit(event, result)
  end
end
