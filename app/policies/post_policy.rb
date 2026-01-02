class PostPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
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

  def index_post?
    admin?
  end
  def analyze_sentiment?
    admin?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end

