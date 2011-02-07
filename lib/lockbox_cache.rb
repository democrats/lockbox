require 'forwardable'

module LockBoxCache
  class Cache
    extend Forwardable
    def_delegators :@cache, :write, :read, :delete, :clear
    
    class HashCache
      def initialize
        @store = Hash.new
      end

      def write(key, value)
        @store[key] = value
      end

      def read(key)
        @store[key]
      end

      def delete(key)
        @store.delete(key)
      end
      
      def clear
        @store = {}
      end
    end
    
    def initialize(use_rails_cache=true)
      if use_rails_cache && defined?(Rails)
        @cache = Rails.cache
      else
        @cache = HashCache.new
      end
    end
  end
end
