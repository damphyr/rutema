# Copyright (c) 2021 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

##
# The top-level module of rutema encompassing all its functionality.
module Rutema
  ##
  # Version information of the rutema gem
  module Version
    ##
    # The major version of the rutema gem
    MAJOR = 2
    ##
    # The minor version of the rutema gem
    MINOR = 0
    ##
    # The tiny version of the rutema gem
    TINY = 1
    ##
    # The version information of the rutema gem as a string
    STRING = [MAJOR, MINOR, TINY].join(".")
  end
end
