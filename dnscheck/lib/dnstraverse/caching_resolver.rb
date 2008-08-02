require 'dnsruby'

require 'dnstraverse/log'

module DNSCheck
  
  class CachingResolver < Dnsruby::Resolver
    
    attr_reader :requests, :cache_hits
    
    def initialize(*args)
      @cache = Hash.new
      @requests = 0
      @cache_hits = 0
      super(*args)
    end
    
    def query(name, type, klass = Dnsruby::Classes.IN)
      @requests+= 1
      ip = self.config.nameserver[0]
      udp_size = self.udp_size
      self.udp_size = udp_size # workaround for bug in dnsruby
      Log.debug { "Querying #{name} to #{ip} class #{klass} type #{type}"}
      key = "#{ip}:#{name}:#{klass}:#{type}:#{udp_size}"
      if @cache.has_key?(key) then
        Log.debug { "Cache hit: #{key}" }
        @cache_hits+= 1
        return @cache[key]
      end
      msg = Dnsruby::Message.new
      msg.add_question(name, type, klass)
      q = Queue.new
      send_async(msg, q)
      id, result, error = q.pop
      @cache[key] = result || error
      Log.debug { "Cache store: #{key}" }
      @cache[key]
    end
    
  end

end