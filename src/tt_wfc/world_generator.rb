require 'tt_wfc/tile'

module Examples
  module WFC

    class WorldGenerator

      # @return [Integer]
      attr_reader :width, :height

      # @return [Array<TileDefinition>] definitions
      attr_reader :definitions

      # @param [Integer] width
      # @param [Integer] height
      # @param [Array<TileDefinition>] definitions
      def initialize(width, height, definitions)
        @width = width
        @height = height
        @definitions = definitions # Tile Definitions
        @state = nil
        @timer = nil
      end

      # @return [void]
      def run(seconds = 0.5)
        model = Sketchup.active_model
        # Not disabling UI because this will be a "long operation" that uses a
        # timer for the main loop.
        model.start_operation('Generate World') # rubocop:disable SketchupPerformance/OperationDisableUI
        tiles = setup(model)
        @state = State.new(tiles)
        @timer = UI.start_timer(seconds, true, &method(:update))
      end

      def stop
        UI.stop_timer(@timer) if @timer
      end

      def update
        puts 'update...'
      end

      private

      State = Struct.new(:tiles)

      # @param [Sketchup::Model] model
      # @return [Array<Tile>]
      def setup(model)
        placeholder = generate_placeholder(model)
        instances = generate_instance_grid(model, placeholder)
        instances.map.with_index { |instance, i|
          Tile.new(self, instance, i)
        }
      end

      # @param [Sketchup::Model] model
      # @return [Sketchup::ComponentDefinition]
      def generate_placeholder(model)
        definition = model.definitions.add('WFC Placeholder')
        points = [
          Geom::Point3d.new(0, 0, 0),
          Geom::Point3d.new(1.0.m, 0, 0),
          Geom::Point3d.new(1.0.m, 1.0.m, 0),
          Geom::Point3d.new(0, 1.0.m, 0),
        ]
        face = definition.entities.add_face(points)
        face.reverse! if face.normal.samedirection?(Z_AXIS.reverse)
        face.material = 'pink'
        face.back_material = 'purple'
        definition
      end

      # @param [Sketchup::Model] model
      # @param [Sketchup::ComponentDefinition] placeholder
      # @return [Array<Sketchup::ComponentInstance>]
      def generate_instance_grid(model, placeholder)
        offset = 500.mm
        instances = []
        group = model.entities.add_group
        group.transform!(Geom::Vector3d.new(0, 0, 1.m))
        width.times { |x|
          height.times { |y|
            point = Geom::Point3d.new((x+1) * offset, (y+1) * offset, 0)
            tr = Geom::Transformation.translation(point)
            instances << group.entities.add_instance(placeholder, tr)
          }
        }
        instances
      end

    end

  end
end
