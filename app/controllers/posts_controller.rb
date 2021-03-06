# encoding: utf-8

require 'digest/sha1'

class PostsController < ApplicationController
  include DrawingsController

  caches_page   :count

  requires_authentication except: [:count]
  requires_user           except: [:count, :since, :search]
  protect_from_forgery    except: [:drawing]

  before_action :find_discussion,              except: [:search]
  before_action :verify_viewable,              except: [:search, :count, :since]
  before_action :find_post,                    only: [:show, :edit, :update, :destroy]
  before_action :verify_editable,              only: [:edit, :update, :destroy]
  before_action :require_and_set_search_query, only: [:search]
  before_action :verify_postable,              only: [:create, :drawing]

  after_action :mark_exchange_viewed,   only: [:since]
  after_action :mark_conversation_viewed, only: [:since]
  #after_action :notify_mentioned,         only: [:create]

  respond_to :html, :mobile, :json

  def count
    @count = @exchange.posts_count
    respond_to do |format|
      format.json do
        render json: {posts_count: @count}.to_json
      end
    end
  end

  def since
    @posts = @exchange.posts.limit(200).offset(params[:index]).for_view
    if request.xhr?
      render layout: false
    end
  end

  def search
    @search_path = search_posts_path
    @posts = Post.search_results(search_query, user: current_user, page: params[:page])
  end

  def create
    create_post(post_params.merge(user: current_user))
  end

  def update
    @post.update_attributes(post_params.merge(edited_at: Time.now))
    respond_with(
      @post,
      location: polymorphic_url(@exchange, page: @post.page, anchor: "post-#{@post.id}")
    )
  end

  def preview
    @post = @exchange.posts.new(post_params.merge(user: current_user))
    if request.xhr?
      render layout: false
    end
  end

  def edit
    if request.xhr?
      render layout: false
    end
  end

  private

  def create_post(create_params)
    @post = @exchange.posts.create(create_params)
    @exchange.reload
    respond_with(
      @post,
      location: polymorphic_url(@exchange, page: @exchange.last_page, anchor: "post-#{@post.id}")
    )

    Thread.new do
      @exchange.posts.collect(&:user_id).uniq.each do |user_id|
        if @current_user.id != user_id
          Mailer.new_post(@current_user.username, User.find(user_id.to_s).email ,location, @exchange.title).deliver_now
        end
      end
    end
  end

  def find_discussion
    @exchange = nil
    @exchange ||= Discussion.find(params[:discussion_id])     if params[:discussion_id]
    @exchange ||= Conversation.find(params[:conversation_id]) if params[:conversation_id]
    @exchange ||= Exchange.find(params[:exchange_id])
  end

  def find_post
    @post = Post.find(params[:id])
  end

  def mark_conversation_viewed
    if @exchange.kind_of?(Conversation)
      current_user.mark_conversation_viewed(@exchange)
    end
  end

  def mark_exchange_viewed
    if current_user? && @posts.any?
      current_user.mark_exchange_viewed(@exchange, @posts.last, (params[:index].to_i + @posts.length))
    end
  end

  def notify_mentioned
    # if @post.valid? && @post.mentions_users?
    #   @post.mentioned_users.each do |mentioned_user|
    #     logger.info "Mentions: #{mentioned_user.username}"
    #   end
    # end
  end

  def post_params
    params.require(:post).permit(:body, :format)
  end

  def search_query
    params[:query] || params[:q]
  end

  def require_and_set_search_query
    unless @search_query = search_query
      flash[:notice] = "No query specified!"
      redirect_to root_url and return
    end
  end

  def verify_editable
    unless @post.editable_by?(current_user)
      flash[:notice] = "You don't have permission to edit that post!"
      redirect_to polymorphic_url(@exchange, page: @exchange.last_page) and return
    end
  end

  def verify_postable
    unless @exchange.postable_by?(current_user)
      flash[:notice] = "This discussion is closed, you don't have permission to post here"
      redirect_to polymorphic_url(@exchange, page: @exchange.last_page)
    end
  end

  def verify_viewable
    unless @exchange && @exchange.viewable_by?(current_user)
      flash[:notice] = "You don't have permission to view that discussion!"
      redirect_to root_url and return
    end
  end

end
