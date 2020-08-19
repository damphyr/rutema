# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: false

module Rutema
  ##
  # Generic base class for all Rutema errors
  #
  # Currently Rutema derives the more specific Rutema::ParserError,
  # Rutema::ReportError and Rutema::RunnerError from it.
  class RutemaError < RuntimeError
  end

  ##
  # Rutema::ParserError is raised when parsing a specification fails
  #
  # The exception may be thrown for errors within the parser subsystem itself
  # as well as for errors encountered within the parsed specifications.
  class ParserError < RutemaError
  end

  ##
  # Rutema::RunnerError is raised on unexpected errors in the runner
  class RunnerError < RutemaError
  end

  ##
  # Rutema::ReportError is raised on errors with the reporting subsystem
  class ReportError < RutemaError
  end
end
