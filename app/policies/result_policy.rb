class ResultPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    same_customer? || super_admin?
  end

  def upsert?
    admin?
  end

  def destroy?
    (same_customer? && admin?) || super_admin?
  end

  def destroy_all?
    admin? || super_admin?
  end

  class Scope < Scope
    def resolve
      return scope.all if super_admin?
      scope.where(customer_id: user.customer_id)
    end
  end

  private

  def same_customer?
    record.customer_id == user.customer_id
  end
end
