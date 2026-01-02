class ModelPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    super_admin?
  end

  def update?
    super_admin?
  end

  def destroy?
    super_admin?
  end

  def destroy_all?
    super_admin?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end

