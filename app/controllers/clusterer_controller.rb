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
  
  # Removes postcodes and company type from
  # company names.
  # * *Args*    :
  #   - +name+  -> string name
  # * *Returns* :
  #   - name without postcode and company type 
  def clean_name(name)
    return remove_company_type(remove_postcode(name))
  end
  
  # Removes postcodes (or other long numbers) from
  # company names. Assumes that it is a postcode if
  # the number is 3 or more digits.
  # * *Args*    :
  #   - +name+  -> string name
  # * *Returns* :
  #   - name without postcode 
  def remove_postcode(name)
    return name.gsub(/\d{3,}/, '').strip
  end

  # Removes company types (e.g. GMBH, AG) from their names
  # * *Args*    :
  #   - +name+  -> string name
  # * *Returns* :
  #   - name without company type inside 
  def remove_company_type(name)
    return name.gsub(/(^|\s)(gmbh|ag)($|\s)/i, ' ').strip
  end
  
  # Separates data into two arrays based on inherent
  # naming differences, i.e. Companies are usually
  # written all uppercase, people name are written
  # first letter uppercase, all others lowercase.
  # * *Args*    :
  #   - +names+ -> array of hashes representing
  #                people and companies
  # * *Returns* :
  #   - array of two arrays: predicted people and
  #     companies respectively 
  def partition_by_type(names)
    return names.partition { |n| n[:val] =~ /[A-Z][a-z]+/}
  end
  
  # Separates, cleans and clusters the names
  # based on their Levenshtein distance.
  # * *Args*    :
  #   - +names+ -> array of hashes representing
  #                people and companies
  # * *Returns* :
  #   - array of arrays: predicted groups - people in
  #     one group, companies clustered into many groups 
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
    # dummy validation
    if params[:names]
        data = params[:names].read
        names = ClusterHelper.parse_csv(data)
        @clusters = ClusterHelper.cluster(names)
    else
        flash.now[:error] = "Please select file"
        render :index
    end
  end
end