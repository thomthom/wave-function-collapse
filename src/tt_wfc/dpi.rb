require 'delegate.rb'

require 'tt_wfc/dpi/inputpoint'
require 'tt_wfc/dpi/pick_helper'
require 'tt_wfc/dpi/view'

module Examples
  module WFC

    module DPI

      # @return [Float]
      def self.scale_factor
        UI.scale_factor
      end

      # @param [Numeric] logical_unit
      # @return [Float]
      def self.to_device(logical_unit)
        logical_unit * scale_factor
      end

      # @param [Numeric] device_unit
      # @return [Float]
      def self.to_logical(device_unit)
        device_unit / scale_factor
      end

      # Converts from device pixels to logical pixels.
      #
      # @param [Float] x
      # @param [Float] y
      # @return [Array(Float, Float)]
      def self.logical_pixels(x, y)
        s = DPI.scale_factor
        [x / s, y / s]
      end

      # Converts from logical pixels to device pixels.
      #
      # @param [Float] x
      # @param [Float] y
      # @return [Array(Float, Float)]
      def self.device_pixels(x, y)
        s = DPI.scale_factor
        [x * s, y * s]
      end

      # Transformation the scales from logical units to device units.
      #
      # @return [Geom::Transformation]
      def self.scale_to_device_transform
        @tr_scale_to_device ||= Geom::Transformation.scaling(scale_factor,
                                                             scale_factor,
                                                             scale_factor)
        @tr_scale_to_device
      end

      # Transformation the scales from device units to logical units.
      #
      # @return [Geom::Transformation]
      def self.scale_to_logical_transform
        @tr_scale_to_logical ||= scale_to_device_transform.inverse
        @tr_scale_to_logical
      end

      # @param [Enumerable<Geom::Point3d>] points
      def self.scale_points(points)
        tr = DPI.scale_to_device_transform
        points.map { |point| point.transform(tr) }
      end

      # @param [Numeric] width
      # @return [Numeric]
      def self.scale_line_width(width)
        to_device(width)
      end

    end # module

  end # module
end # module
