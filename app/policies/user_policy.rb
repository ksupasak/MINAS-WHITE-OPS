class UserPolicy < ApplicationPolicy
  def index?
    admin? || super_admin?
  end

  def show?
    super_admin? || same_customer?
  end

  def create?
    admin?
  end

  def update?
    admin? || user == record
  end

  def destroy?
    admin? && !record.super_admin?
  end

  def destroy_all?
    admin?
  end

  class Scope < Scope
    def resolve
      return scope.all if super_admin?
      scope.where(customer_id: user.customer_id)
    end
  end

  private

  def same_customer?
    user.customer_id == record.customer_id
  end
end
