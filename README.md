Flamingo
========
Flamingo is a resque-based system for handling the Twitter Streaming API.

Dependencies
------------
* redis
* resque
* sinatra
* twitter-stream
* yajl-ruby

By default, the `resque` gem installs the latest 2.x `redis` gem, so if
you are using Redis 1.x, you may want to swap it out.

    $ gem list | grep redis
    redis (2.0.3)
    $ gem remove redis --version=2.0.3 -V

    $ gem install redis --version=1.0.7
    $ gem list | grep redis
    redis (1.0.7)

Getting Started
---------------

1. Edit `config/flamingo.yml`

        username: USERNAME
        password: PASSWORD
        stream: filter
        logging:
          dest: /YOUR/LOG/PATH.LOG
          level: LOGLEVEL

    `LOGLEVEL` is one of the following:
    `DEBUG` < `INFO` < `WARN` < `ERROR` < `FATAL` < `UNKNOWN`

2. Start the Redis server

        $ redis-server

3. Configure tracking using `flamingo` client

        $ ruby bin/flamingo
        >> s = Stream.get(:filter)
        >> s.params[:track] = %w(FOO BAR BAZ)
        >> Subscription.new('YOUR_QUEUE').save

4. Start the Flamingo Daemon (`flamingod`)

        $ ruby bin/flamingod

5. View progress via logging

        $ tail -f log/flamingo.log

6. View progress via `resque-web`

        $ resque-web
        [...] Starting 'resque-web'...
        [...] 'resque-web' is already running at http://0.0.0.0:5678
        
7. Consume events with a resque worker

        class HandleFlamingoEvent
          
          # type: One of "tweet" or "delete"
          # event: a hash of the json data from twitter
          def self.perform(type,event)
            # Do stuff with the data
          end
          
        end
        
        $ QUEUE=YOUR_QUEUE rake resque:work
