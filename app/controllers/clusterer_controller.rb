require 'csv'
require 'scluster'

module ClusterHelper
  
  MAX_DISTANCE = 0.5
  
  def parse_csv(data)
    names = []
    csv = CSV(data, :quote_char => '"', :col_sep => ';')
    csv.each do |line|
      names << { :name => line[0], :val => clean_name(line[0]), :group => line[1] }
    end
    
    return names
  end
  
  def clean_name(name)
    return remove_company_type(remove_postcode(name))
  end
  
  def remove_postcode(name)
    return name.gsub(/\d{3,}/, '').strip
  end

  def remove_company_type(name)
    return name.gsub(/(^|\s)(gmbh|ag)($|\s)/i, ' ').strip
  end
  
  def partition_by_type(names)
    return names.partition { |n| n[:val] =~ /[A-Z][a-z]+/}
  end
  
  def cluster(names)
    persons, companies = partition_by_type(names)
    
    clusterer = SCluster::Clusterer.new(companies, MAX_DISTANCE)
    clusterer.cluster
    
    return clusterer.to_a + [persons]
  end
  
end

include ClusterHelper

class ClustererController < ApplicationController
  def index
  end
  
  def cluster
    data = params[:names].read
    names = ClusterHelper.parse_csv(data)
    @clusters = ClusterHelper.cluster(names)
  end
end


