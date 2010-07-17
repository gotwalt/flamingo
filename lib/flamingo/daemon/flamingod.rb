module Flamingo
  FLAMINGO_SLEEP_DELAY = ENV['FLAMINGO_SLEEP_DELAY'].to_i || 0
  module Daemon
    #
    # Flamingod is the main overseer of the Flamingo flock.
    #
    # Starts three sets of children:
    #
    # * A wader process: initiates stream request, pushes each response into the queue
    # * A Sinatra server: lightweight responder to create and manage subscriptions
    # * A set of dispatchers: worker processes that handle each stream response.
    #
    # You can control the flamingod with the following signals:
    #
    # * TERM and INT will kill the flamingod parent process, and signal each
    #   child with TERM
    # * USR1 will restart the wader gracefully.
    #
    class Flamingod

      def exit_signaled?
        @exit_signaled
      end

      def exit_signaled=(val)
        @exit_signaled = val
      end

      def start_new_wader
        wader = WaderProcess.new
        wader.start
        wader
      end

      def start_new_dispatcher
        dispatcher = DispatcherProcess.new
        dispatcher.start
        dispatcher
      end

      def start_new_server
        server = ServerProcess.new
        server.start
        server
      end

      def trap_signals
        trap("TERM") { terminate! }
        trap("INT")  { terminate! }
        trap("USR1") { restart_wader }
      end

      def restart_wader
        @wader.kill("INT")
      end

      def signal_children(sig)
        children.each {|child| child.signal(sig) }
      end

      def terminate!
        puts "Terminating..."
        self.exit_signaled = true
        signal_children("TERM")
      end

      def children
        [@wader] + @dispatchers
      end

      def start_children
        @wader = start_new_wader
        @dispatchers = [start_new_dispatcher]
        @server = start_new_server
      end

      #
      # Unless signaled externally, waits in an endless loop. If any child
      # process terminates, it attends an optional delay (set by
      # Flamingo::FLAMINGO_SLEEP_DELAY) and then restarts that process.
      #
      def wait_on_children()
        until exit_signaled?
          child_pid = Process.wait(-1)
          unless exit_signaled?
            if @wader.pid == child_pid
              print "Wader died" ; sleep Flamingo::FLAMINGO_SLEEP_DELAY ; puts " ...restarting wader"
              @wader = start_new_wader
            elsif @server.pid == child_pid
              print "Server died" ; sleep Flamingo::FLAMINGO_SLEEP_DELAY ; puts " ...restarting server"
              @server = start_new_server
            elsif (to_delete = @dispatchers.find{|d| d.pid == child_pid})
              @dispatchers.delete(to_delete)
              print "Dispatcher #{child_pid} died" ; sleep Flamingo::FLAMINGO_SLEEP_DELAY ; puts " ...restarting dispatcher"
              @dispatchers << start_new_dispatcher
            else
              puts "Received exit from unknown child #{child_pid}"
            end
          end
        end
        puts "Exited"
      end

      def run
        trap_signals
        start_children
        wait_on_children
      end
    end
  end
end
