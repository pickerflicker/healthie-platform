class EnrollmentsController < ApplicationController
  after_action :verify_policy_scoped

  def index
    authorize Enrollment
    @enrollment = current_user.client.enrollments.build if current_user.client?
    load_lists
  end

  def create
    @enrollment = Enrollment.new(client: current_user.client)
    authorize @enrollment
    input = params.expect(enrollment: [ :provider_id, :plan ])
    @enrollment.provider = policy_scope(Provider, policy_scope_class: ProviderDirectoryPolicy::Scope).find(input[:provider_id])
    @enrollment.plan = input[:plan] if input.key?(:plan)
    if @enrollment.save
      redirect_to enrollments_path, notice: "Provider added.", status: :see_other
    else
      render_invalid
    end
  rescue ActiveRecord::RecordNotUnique
    # The database is authoritative when competing submissions pass validation.
    @enrollment.errors.add(:provider, "is already enrolled")
    render_invalid
  end

  def destroy
    @enrollment = policy_scope(Enrollment).find(params[:id])
    authorize @enrollment
    @enrollment.destroy!
    redirect_to enrollments_path, notice: "Provider removed. Your journal entries have been kept.", status: :see_other
  end

  private

  def render_invalid
    load_lists
    render :index, status: :unprocessable_entity
  end

  def load_lists
    if current_user.client?
      @provider_list = policy_scope(Client).find(current_user.client.id).provider_list
      @available_providers = policy_scope(Provider, policy_scope_class: ProviderDirectoryPolicy::Scope)
        .where.not(id: current_user.client.enrollments.select(:provider_id)).includes(:user).order(:id)
    else
      @enrollments = policy_scope(Enrollment).preload(client: :user).order(created_at: :desc, id: :desc)
    end
  end
end
