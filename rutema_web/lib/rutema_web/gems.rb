require 'rubygems'
gem 'ramaze','=2008.06'
require 'ramaze'
#this fixes a clash with activesupport 2.1.1 (because it checks start_with? but not end_with?)
#and Ramaze on 1.8.6 only creates a start_with? method
class String; undef_method :start_with? end
gem 'activerecord','=2.1.1'
require 'active_record'
gem 'rutema',">=1.0.0"
require 'patir/configuration'
require 'patir/command'
require 'patir/base'
require 'ruport/acts_as_reportable'
