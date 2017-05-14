class CommentsController < ApplicationController
  # コメントを保存、投稿する為のアクション
  def create
    # Blogをパラメータの値から探し出し,Blogに紐づくcommentsとしてbuildします。
    @comment = current_user.comments.build(comment_params)
    @blog = @comment.blog
    @notification = @comment.notifications.build(user_id: @blog.user.id)
    # 自分のブログへコメントする場合は既読にしておく
    @notification.read = true if @comment.blog.user_id == current_user.id
    # クライアント要求に応じてフォーマットを変更
    respond_to do |format|
      if @comment.save

        format.html { redirect_to blog_path(@blog), notice: 'コメントを投稿しました。'}
        format.js {render :index}

        # 通知処理
        unless @comment.blog.user_id == current_user.id
          Pusher.trigger("user_#{@comment.blog.user_id}_channel", 'comment_created',{
            message: 'あなたの作成したブログにコメントが付きました'
            })
        end

        # 通知未読カウント処理
        Pusher.trigger("user_#{@comment.blog.user_id}_channel", 'notification_created', {
          unread_counts: Notification.where(user_id: @comment.blog.user.id, read: false).count
          })
      else
        format.html {render :new}
      end
    end
  end

  def edit
    @comment = Comment.find(params[:id])
    @blog = @comment.blog
  end

  def update
    @comment = Comment.find(params[:id])
    @blog = @comment.blog
    @comment.update(comment_params)
    if @comment.save
      redirect_to blog_path(@blog), notice: "コメントを更新しました。"
    else
      render 'edit'
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @blog = @comment.blog
    respond_to do |format|
      @comment.destroy
      format.html {redirect_to blog_path(@blog), 'コメントを削除しました。'}
      format.js {render :index}
    end
  end

  private
    # strong parameter
    def comment_params
      params.require(:comment).permit(:blog_id, :content)
    end



end
