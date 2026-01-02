class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]

  def index
    @users = policy_scope(User).order_by(created_at: :desc)
    authorize User
  end

  def show
    authorize @user
  end

  def new
    @user = User.new(customer: Current.customer)
    authorize @user
  end

  def edit
    authorize @user
  end

  def create
    @user = User.new(user_params)
    @user.customer ||= Current.customer unless current_user.super_admin?
    authorize @user

    if @user.save
      redirect_to users_path, notice: "User created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @user
    attrs = user_params
    attrs.except!(:password, :password_confirmation) if attrs[:password].blank?

    if @user.update(attrs)
      redirect_to users_path, notice: "User updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user
    @user.destroy
    redirect_to users_path, notice: "User deleted"
  end

  def destroy_all
    authorize User, :destroy_all?
    policy_scope(User).destroy_all
    redirect_to users_path, notice: "All users deleted"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    permitted = %i[email password password_confirmation role]
    permitted << :customer_id if current_user.super_admin?
    params.require(:user).permit(permitted)
  end
end
