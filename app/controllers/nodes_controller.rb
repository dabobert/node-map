class NodesController < ApplicationController

  def show
    if params[:depth].blank?
      depth = 1
    else
      depth = params[:depth].to_i
    end
    
    before  = Time.new
    origin  = Node.find(params[:id]).origin(depth)
    after   = Time.new
    origin["duration"] = Time.at(after-before).gmtime.strftime('%R:%S')
    render :json => origin.to_json
  end

end
