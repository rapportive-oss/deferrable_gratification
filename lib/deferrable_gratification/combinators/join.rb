require File.join(File.dirname(__FILE__), *%w[.. default_deferrable])

module DeferrableGratification
  module Combinators
    # Abstract base class for combinators that depend on a number of
    # asynchronous operations (potentially executing in parallel).
    #
    # @abstract Subclasses should override {#done?} to define whether they wait
    #   for some or all of the operations to complete, and {#finish} to define
    #   what they do when {#done?} returns true.
    class Join < Base
      # Prepare to wait for the completion of +operations+.
      #
      # Does not actually set up any callbacks or errbacks: call {#setup!} for
      # that.
      #
      # @param [*Deferrable] *operations deferred statuses of asynchronous
      #   operations to wait for.
      def initialize(*operations)
        super()
        @operations = operations
      end

      # Register callbacks and errbacks on the supplied operations to notify
      # this {Join} of completion.
      def setup!
        finish if done?
        @operations.each &method(:register_attempt)
      end

      # Create a {Join} and register the callbacks.
      #
      # @param (see #initialize)
      #
      # @return [Join] Deferrable representing the join operation.
      def self.setup!(*operations)
        new(*operations).tap(&:setup!)
      end


      # Combinator that waits for any of the supplied asynchronous operations
      # to succeed, and succeeds with the result of the first (chronologically)
      # to do so.
      #
      # This Deferrable will fail if all the operations fail.  It may never
      # succeed or fail, if one of the operations also does not.
      #
      # You probably want to call {ClassMethods#join_first_success} rather than
      # using this class directly.
      class FirstSuccess < Join
        private
        def done?
          successes.length > 0
        end

        def finish
          succeed(successes.first)
        end
      end


      # Combinator that waits for all of the supplied asynchronous operations
      # to succeed or fail, and the succeeds with a list of the successes and
      # a list of the failures.
      #
      # This deferrable will never fail. It may never succeed if one of
      # the supplied operations never completes.
      #
      # You probably want to call {ClassMethods#in_parallel} rather than
      # using this class directly.
      class InParallel < Join
        private
        def done?
          all_completed?
        end

        def finish
          succeed(successes, failures)
        end
      end

      private

      def all_completed?
        successes.length + failures.length >= @operations.length
      end
    end
  end
end
