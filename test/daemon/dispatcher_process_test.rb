require File.join(File.dirname(__FILE__),"..","test_helper")

class DispatcherProcessTest < Test::Unit::TestCase
  
  include FlamingoTestCase
  
  def setup
    setup_flamingo
  end
  
  def test_works_off_flamingo_dispatch_queue
    # Prepare a mock worker that doesn't actually run
    mock_worker = Resque::Worker.new(Flamingo.dispatch_queue)
    mock_worker.expects(:work).with(1)
    
    # Return the mock worker as a result of new assuming new is called with the 
    # dispatch queue as an argument
    Resque::Worker.expects(:new).
      with(Flamingo.dispatch_queue).
      returns(mock_worker)

    proc = Flamingo::Daemon::DispatcherProcess.new
    proc.run #run doesn't fork, which is what we want here
  end
  
  def teardown
    teardown_flamingo
  end
  
end