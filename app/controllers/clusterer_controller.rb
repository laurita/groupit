class ClustererController < ApplicationController
  def index
  end
  
  def cluster
    data = params[:names].read
    puts data
    
    render :index
  end
end
