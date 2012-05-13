require 'oauth'
require 'json'

class IndexController < ApplicationController
  def self.consumer
    OAuth::Consumer.new(
      "keyを設定する",
      "keyを設定する",
      {
        :site => "https://www.yammer.com",
        :request_token_path => "/oauth/request_token",
        :access_token_path => "/oauth/access_token.json",
        :authorize_path => "/oauth/authorize"
      }
    )
  end
  
  def index
  end
  
  def oauth
    request_token = IndexController.consumer.get_request_token(
      :oauth_callback => "http://#{request.host_with_port}/oauth_callback"
    )
    session[:request_token] = request_token.token
    session[:request_token_secret] = request_token.secret
    # 認証する
    redirect_to request_token.authorize_url
    return
  end
  
  def oauth_callback
    consumer = IndexController.consumer
    request_token = OAuth::RequestToken.new(
      consumer,
      session[:request_token],
      session[:request_token_secret]
    )
 
    access_token = request_token.get_access_token(
      {},
      :oauth_token => params[:oauth_token],
      :oauth_verifier => params[:oauth_verifier]
    )
 
    response = consumer.request(
      :get,
      '/oauth/access_token.json',
      access_token, { :scheme => :query_string }
    )
    case response
    when Net::HTTPSuccess
      @user_info = JSON.parse(response.body)
      unless @user_info['screen_name']
        flash[:notice] = "Authentication failed"
        redirect_to :action => :index
        return
      end
    else
      RAILS_DEFAULT_LOGGER.error "Failed to get user info via OAuth"
      flash[:notice] = "Authentication failed"
      redirect_to :action => :index
      return
    end
  end
end
