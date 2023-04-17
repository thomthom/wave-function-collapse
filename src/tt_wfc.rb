require 'sketchup.rb'
require 'extensions.rb'

module Experiment
  module WFC

    unless file_loaded?(__FILE__)
      ex = SketchupExtension.new('Wave Function Collapse Experiments', 'tt_wfc/main')
      ex.description = 'Experiments in Wave Function Collapse algorithm.'
      ex.version     = '1.0.0'
      ex.copyright   = 'Trimble Inc © 2016-2023'
      ex.creator     = 'SketchUp'
      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end

  end # module WFC
end # module Experiment
