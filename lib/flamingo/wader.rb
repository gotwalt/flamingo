module Flamingo
  class Wader
    
    attr_accessor :screen_name, :password, :keep_running, :stream, :connection
    
    def initialize(screen_name,password,stream)
      self.screen_name = screen_name
      self.password = password
      self.stream = stream
    end
    
    def run
      self.keep_running = true
      EventMachine::run do
        self.connection = stream.connect(:auth=>"#{screen_name}:#{password}")
        Flamingo.logger.info("Listening on stream: #{stream.path}")
  
        connection.each_item do |event_json|
          dispatch_event(event_json)
        end
  
        connection.on_error do |message|
          dispatch_error(:generic,message)
        end
  
        connection.on_reconnect do |timeout, retries|
          dispatch_error(:reconnection,
            "Will reconnect after #{timeout}. Retry \##{retries}",
            {:timeout=>timeout,:retries=>retries}
          )
        end
  
        connection.on_max_reconnects do |timeout, retries|
          dispatch_error(:fatal,
            "Failed to reconnect after #{retries} retries",
            {:timeout=>timeout,:retries=>retries}
          )
        end
      end  
    end
    
    def stop
      self.keep_running = false
    end
    
    private
      def dispatch_event(event_json)
        Resque.enqueue(Flamingo::DispatchEvent,event_json)
        stop_if_needed
      end
      
      def dispatch_error(type,message,data={})
        Resque.enqueue(Flamingo::DispatchError,type,message,data)
        stop_if_needed
      end

      def stop_if_needed
        unless keep_running
          Flamingo.logger.info("Terminating gracefully")
          connection.stop
          EM.stop
        end
      end
  end
end