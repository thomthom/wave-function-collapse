module Examples
  module WFC

    class Tile

      # @return [WorldGenerator]
      attr_reader :world

      # @return [Sketchup::ComponentInstance]
      attr_reader :instance

      # @return [Integer]
      attr_reader :index

      # @return [Geom::Point3d]
      attr_reader :position

      # @return [Array<Possibility>]
      attr_reader :possibilities

      # @param [WorldGenerator] world
      # @param [Sketchup::ComponentInstance] instance
      # @param [Integer] index
      def initialize(world, instance, index)
        @world = world
        @instance = instance
        @index = index

        y = index / world.width
        x = index - (y * world.width)
        @position = Geom::Point3d.new(x, y, 0)

        # TODO: Refactor out the `world` dependency.
        @possibilities = world.possibilities.dup
      end

      # @return [Integer]
      def entropy
        possibilities.size
      end

      # @return [Float]
      def shannon_entropy
        @shannon_entropy ||= compute_shannon_entropy
      end

      def resolved?
        entropy == 1
      end

      def unresolved?
        entropy > 1
      end

      def failed?
        entropy == 0
      end

      def untouched?
        entropy == world.possibilities.size
      end

      # @param [Array<Possibility>] possibilities
      # @return [void]
      def remove_possibilities(possibilities)
        possibilities.each { |possibility|
          warn "#{self} unable to remove possibility" if @possibilities.delete(possibility).nil?
        }
        raise "#{self} failed to resolve after removing #{possibilities.size} possibilities" if failed?
        update
      end

      # @param [Possibility] possibility
      # @return [void]
      def remove_possibility(possibility)
        raise 'already resolved' if resolved?
        if possibilities.delete(possibility)
          update
        end
      end

      # @param [Possibility] possibility
      # @return [void]
      def resolve_to(possibility)
        raise 'already resolved' if resolved?
        raise 'possibility not found' unless possibilities.select! { |item| item == possibility }
        raise "#{self} failed to resolve" if failed?
        update
      end

      # @param [Tile] tile
      # @return [Integer]
      def edge_index_to_neighbor(tile)
        # :north, :east, :south, :west
        if tile.north_of?(self)
          0
        elsif tile.east_of?(self)
          1
        elsif tile.south_of?(self)
          2
        elsif tile.west_of?(self)
          3
        else
          raise "#{self} to #{tile} share no edge"
        end
      end

      # @param [Tile] tile
      def north_of?(tile)
        position.x == tile.position.x &&
        position.y == tile.position.y + 1
      end

      # @param [Tile] tile
      def east_of?(tile)
        position.x == tile.position.x + 1 &&
        position.y == tile.position.y
      end

      # @param [Tile] tile
      def south_of?(tile)
        position.x == tile.position.x &&
        position.y == tile.position.y - 1
      end

      # @param [Tile] tile
      def west_of?(tile)
        position.x == tile.position.x - 1 &&
        position.y == tile.position.y
      end

      # @return [String]
      def to_s
        x, y = position.to_a.map(&:to_i)
        "Tile<(#{x}, #{y} [#{index}]) #{entropy}:#{world.possibilities.size}>"
      end
      alias inspect to_s

      private

      # @return [void]
      def update
        if resolved?
          puts "Resolved #{self}. (Instance: #{instance.persistent_id})" if Sketchup.read_default('TT_WFC', 'Log', false) # TODO: Kludge
          possibility = possibilities.first
          instance.definition = possibility.prototype.definition

          tr = Geom::Transformation.translation(instance.transformation.origin)
          instance.transformation = tr * possibility.transformation

          # TODO: Refactor attributes to AssetManager.
          instance.set_attribute('tt_wfc', 'type', instance.definition.name)
          instance.set_attribute('tt_wfc', 'weight', possibility.weight)
        else
          instance.material = world.material_from_entropy(entropy)
        end
        @shannon_entropy = nil
      end

      def compute_shannon_entropy
        # https://robertheaton.com/2018/12/17/wavefunction-collapse-algorithm/
        # https://github.com/robert/wavefunction-collapse
        #
        # Sums are over the weights of each remaining
        # allowed tile type for the square whose
        # entropy we are calculating.
        #     shannon_entropy_for_square =
        #       log(sum(weight)) -
        #       (sum(weight * log(weight)) / sum(weight))
        #
        # https://github.com/mxgmn/WaveFunctionCollapse/blob/a6f79f0f1a4220406220782b71d3fcc73a24a4c2/Model.cs#L55-L67
        sum_weight = possibilities.sum(&:weight).to_f
        sum_times_log_weight = possibilities.sum { |n| n.weight * Math.log(n.weight) }
        sum_weight - (sum_times_log_weight / sum_weight)
      end

    end

  end
end
