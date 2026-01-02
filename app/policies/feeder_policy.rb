class FeederPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    same_customer? || super_admin?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  def destroy_all?
    admin?
  end

  def run_now?
    admin?
  end

  def reprocess?
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
    record.customer_id == user.customer_id
  end
end
