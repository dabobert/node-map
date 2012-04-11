class NodesController < ApplicationController

  def show
    render :json =>Node.find(params[:id]).origin.to_json 
  end

end
