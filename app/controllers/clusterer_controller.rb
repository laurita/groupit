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
  
  # Predict the group name based on the longest common
  # substring of the cleaned names of all the points
  # in the cluster. 
  def predict_group_name(cluster)
    first_val = cluster[0][:val]
    # find longest common substring
    group_name = cluster.inject(first_val) do |intersection, point|
      find_longest_common_substring(intersection, point[:val])
    end
    # take the longest word possibly joined with '&' or '-'
    if (group_name != '')
      group_name = group_name.scan(/[[:alnum:]|&|-[:alnum]]+/).sort_by(&:length).last
    else
      puts group_name.class
      group_name = 'Person'
    end
    group_name
  end
  
  # Finds the longest common substring between twp strings.
  # Taken from
  # http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Longest_common_substring#Ruby
  # * *Args*    :
  #   - +s1+    -> string
  #   - +s2+    -> string
  # * *Returns* :
  #   - longest common substring
  def find_longest_common_substring(s1, s2)
      if (s1 == "" || s2 == "")
        return ""
      end
      m = Array.new(s1.length){ [0] * s2.length }
      longest_length, longest_end_pos = 0,0
      (0 .. s1.length - 1).each do |x|
        (0 .. s2.length - 1).each do |y|
          if s1[x] == s2[y]
            m[x][y] = 1
            if (x > 0 && y > 0)
              m[x][y] += m[x-1][y-1]
            end
            if m[x][y] > longest_length
              longest_length = m[x][y]
              longest_end_pos = x
            end
          end
        end
      end
      return s1[longest_end_pos - longest_length + 1 .. longest_end_pos]
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
        puts @clusters.inspect
        @clusters.each do |cluster|
          predicted_group_name = predict_group_name(cluster)
          puts cluster
          puts "predicted group name" 
          puts predicted_group_name
          cluster.each do |point|
            point[:predicted_group] = predicted_group_name
          end
        end
    else
        flash.now[:error] = "Please select file"
        render :index
    end
  end

end