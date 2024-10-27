# frozen_string_literal: true

class EventEmitter
  def initialize
    @callbacks = {}
  end

  def on(event, &callback)
    @callbacks[event] = callback
  end

  def method_missing(name, *_args, &block)
    raise ArgumentError, "No block given when registering '#{name}' callback." if block.blank?

    @callbacks[name.to_s] = block
  end

  def respond_to_missing?(_name)
    true
  end

  def call(name, *args)
    @callbacks[name.to_sym]&.call(*args)
  end
  alias emit call
end
