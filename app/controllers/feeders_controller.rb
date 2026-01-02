class FeedersController < ApplicationController
  before_action :set_feeder, only: %i[show edit update destroy run_now reprocess]
  before_action :load_dependencies, only: %i[new edit create update]

  def index
    @feeders = policy_scope(Feeder).order_by(created_at: :desc)
    authorize Feeder
  end

  def show
    authorize @feeder
  end

  def new
    @feeder = Feeder.new(status: "idle", customer: Current.customer)
    @feeder.build_feeder_config
    authorize @feeder
  end

  def edit
    authorize @feeder
    @feeder.build_feeder_config unless @feeder.feeder_config
  end

  def create
    @feeder = Feeder.new(feeder_params)
    @feeder.customer ||= Current.customer unless current_user.super_admin?
    authorize @feeder

    if @feeder.save
      sync_subjects(@feeder)
      redirect_to @feeder, notice: "Feeder created"
    else
      load_dependencies
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @feeder
    if @feeder.update(feeder_params)
      sync_subjects(@feeder)
      redirect_to @feeder, notice: "Feeder updated"
    else
      load_dependencies
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @feeder
    @feeder.destroy
    redirect_to feeders_path, notice: "Feeder deleted"
  end

  def destroy_all
    authorize Feeder, :destroy_all?
    policy_scope(Feeder).destroy_all
    redirect_to feeders_path, notice: "All feeders deleted"
  end

  def run_now
    authorize @feeder, :run_now?
    RunFeederJob.perform_async(@feeder.id.to_s)
    redirect_to @feeder, notice: "Feeder enqueued"
  end

  def reprocess
    authorize @feeder, :reprocess?
    

    @feeder.reprocess
    redirect_to @feeder, notice: "Feeder reprocessed"
  end

  private

  def set_feeder
    @feeder = Feeder.find(params[:id])
  end

  def load_dependencies
    @feeder_types = FeederType.all.order_by(name: :asc)
    @projects = policy_scope(Project)
    @subjects = policy_scope(Subject)
  end

  def feeder_params
    permitted = %i[name status schedule_cron feeder_type_id]
    permitted << :customer_id if current_user.super_admin?
    permitted << { feeder_config_attributes: %i[id api_key api_secret access_token refresh_token base_url rate_limit_policy engine google_domain gl hl start extra] }
    attrs = params.require(:feeder).permit(permitted)
    if attrs[:feeder_config_attributes]
      extra = attrs[:feeder_config_attributes][:extra]
      if extra.is_a?(String) && extra.present?
        attrs[:feeder_config_attributes][:extra] = JSON.parse(extra) rescue {}
      elsif extra.is_a?(String)
        attrs[:feeder_config_attributes][:extra] = {}
      end
    end
    attrs
  end

  def sync_subjects(feeder)
    ids = Array(params[:feeder][:subject_ids]).reject(&:blank?)
    feeder.feeder_subjects.where(:subject_id.nin => ids).destroy_all
    ids.each do |sid|
      feeder.feeder_subjects.find_or_create_by(subject_id: sid)
    end
  end
end
