require 'rho/rhocontroller'
require 'helpers/browser_helper'

class MyFreightController < Rho::RhoController
  include BrowserHelper

  #GET /MyFreight
  def index
    @just_bought = @params["just_bought"] 
    #Very hacky but we cant WebView.navigate to show a freight
    if @just_bought
      @freight = MyFreight.find(:all).last()
      render :action => :show
    else
      @msg = @params['message']
      @freights = MyFreight.find(:all)
      @nofreights = @params['nofreights']
      if @freights.empty? and !@nofreights
        WebView.navigate(url_for(:controller => :MyFreight, :action => :do_search), WebView.active_tab )
      else
        render
      end
    end
  end

  # GET /MyFreight/{1}
  def show
    @freight = MyFreight.find(@params['id'])
    if @freight
      render :action => :show
    else
      redirect :action => :index
    end
  end

  def search
    render
  end
  
  def do_search
    Rho::AsyncHttp.get(
      :url => "http://#{application_url}/tickets.json",
      :headers => {'Cookie' => User.find(:first).cookie },
      :callback => '/app/MyFreight/search_callback')
    WebView.navigate(url_for(:controller => :Settings, :action => 'wait'), 1)
  end
  
  def search_callback
    errCode = @params['error_code'].to_i
    if errCode == 0
      MyFreight.delete_all
      @params['body'].each do |attributes|
        freight = MyFreight.new(attributes)
        freight.save
      end
      WebView.navigate((url_for :controller => :MyFreight, 
                                :action => :index, 
                                :query => {:nofreights => MyFreight.find(:all).empty?}), 1)
    else
      error_message = error_messages(@params['http_error'])
      WebView.navigate((url_for :action => :index, :query => {:message => error_message}), 1)
    end
  end

  # POST /MyFreight/{1}/delete
  def delete
    @freight = MyFreight.find(@params['id'])
    @freight.destroy if @freight
    redirect :action => :index
  end
end
