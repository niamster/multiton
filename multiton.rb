require 'thread'

# The Multiton class extends Singleton Pattern to collection level
# The main purpose is to have a collection of sole instanses of a particular class
# Possible application: a cache mapped to some DB
#
# == Usage
#
# To use Multiton, include it in your class
#   class Klass
#     include Multiton
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
#   class Klass
#     include Multiton
#     attr_reader :ID
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
module Multiton
  attr_reader :id

  def clone
    raise TypeError, "can't clone instance of singleton #{self.class}"
  end

  def dup
    raise TypeError, "can't dup instance of singleton #{self.class}"
  end

  def _dump(depth = -1)
    raise TypeError, "can't marshall instance of singleton #{self.class}"
  end

  class << self
    def __init__(klass)
      klass.instance_eval {
        @multiton__instances__ = {}
        @multiton__mutex__ = Mutex.new
      }

      def klass.new(id, *args, &blk)
        o = allocate
        o.instance_variable_set(:@id, id)
        o.instance_eval{initialize(*args, &blk)}
        o
      end

      def klass.inherited(sub)
        super
        Multiton.__init__(sub)
      end

      def klass.create(id, *args, &blk)
        return @multiton__instances__[id] if @multiton__instances__[id]
        @multiton__mutex__.synchronize {
          return @multiton__instances__[id] if @multiton__instances__[id]
          @multiton__instances__[id] = new(id, *args, &blk)
        }
        @multiton__instances__[id]
      end

      def klass.destroy(id)
        @multiton__mutex__.synchronize {
          return @multiton__instances__.delete id
        }
      end

      def klass.each(*args, &block)
        __instances__ = nil
        @multiton__mutex__.synchronize {
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

    private

    # extending an object with Multiton is a bad idea
    undef_method :extend_object

    def append_features(mod)
      #  help out people counting on transitive mixins
      unless mod.instance_of?(Class)
        raise TypeError, "Inclusion of the Multiton module in module #{mod}"
      end
      super
    end

    def included(klass)
      super
      Multiton.__init__(klass)
      klass.private_class_method :new, :allocate, :inherited
    end
  end
end
