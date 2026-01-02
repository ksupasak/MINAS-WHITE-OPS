class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy]

  def index
    authorize Customer
    @customers = policy_scope(Customer).order_by(name: :asc)
  end

  def show
    authorize @customer
  end

  def new
    @customer = Customer.new
    authorize @customer
  end

  def edit
    authorize @customer
  end

  def create
    @customer = Customer.new(customer_params)
    authorize @customer
    if @customer.save
      redirect_to @customer, notice: "Customer created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @customer
    if @customer.update(customer_params)
      redirect_to @customer, notice: "Customer updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @customer
    @customer.destroy
    redirect_to customers_path, notice: "Customer deleted"
  end

  def destroy_all
    authorize Customer, :destroy_all?
    policy_scope(Customer).destroy_all
    redirect_to customers_path, notice: "All customers deleted"
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:name, :slug, :plan, :status)
  end
end
