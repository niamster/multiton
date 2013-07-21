require "singleton"

# The Multiton class extends Singleton module to collection level
# The main purpose is to have a collection of sole instanses of a particular class
# Possible application: a cache mapped to some DB
#
# == Usage
#
# To use Multiton, inherit it in your class
#   class Klass < Multiton
#     # ...
#   end
#
# A single instance identified by some <ID> is created upon the first call of Klass.create(<ID>)
# This ensures that there's only one instance of the Klass for a given <ID>
#
#   a, b = Klass.create(:id), Klass.create(:id)
#   a == b
#   # => true
#   a.id == b.id
#   # => true
#
# Before the call to Klass.initialize, instance variable @id is assigned to <ID> obtained from Klass.create
#   class Klass < Multiton
#     attr_reader :id
#
#     def initialize
#       @ID = @id
#     end
#   end
#
#   a = Klass.create(:id)
#   a.ID == a.id
#   # => true
#   a.ID == :id
#   # => true
#
# The class Klass that inherits Multiton is final,
# i.e. it's not possible to derive from a Klass anymore
#
class Multiton
  include Singleton

  attr_reader :id

  class << Singleton
    def __init__(klass)
      klass.instance_eval {
        @multiton__instances__ = {}
        @singleton__mutex__ = Mutex.new
      }

      def klass.new(id, *args, &blk)
        o = allocate
        o.instance_variable_set(:@id, id)
        o.instance_eval{initialize(*args, &blk)}
        o
      end
      klass.private_class_method :new

      def klass.instance
        raise TypeError, "can't create a single instance of multiton #{self}"
      end

      def klass.inherited(sub)
        raise TypeError, "can't inherit from of multiton class #{self.class}"
      end

      def klass.create(id, *args, &blk)
        return @multiton__instances__[id] if @multiton__instances__[id]
        @singleton__mutex__.synchronize {
          return @multiton__instances__[id] if @multiton__instances__[id]
          @multiton__instances__[id] = new(id, *args, &blk)
        }
        @multiton__instances__[id]
      end

      def klass.destroy(id)
        @singleton__mutex__.synchronize {
          return @multiton__instances__.delete id
        }
      end

      def klass.each(*args, &block)
        __instances__ = nil
        @singleton__mutex__.synchronize {
          __instances__ = @multiton__instances__.clone
        }
        __instances__.each *args, &block
      end

      def klass.to_a
        instances = []
        each { |k, v| instances << v }
        instances
      end

      def klass.[](id)
        create id
      end

      klass
    end
  end
end
