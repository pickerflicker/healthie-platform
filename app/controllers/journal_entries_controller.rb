class JournalEntriesController < ApplicationController
  after_action :verify_policy_scoped, only: :index
  before_action :set_journal_entry, only: %i[show edit update destroy]

  def index
    authorize JournalEntry
    @journal_entries = policy_scope(JournalEntry)
    if params[:client_id]
      @client = policy_scope(Client).find(params[:client_id])
      authorize @client, :show?
      @journal_entries = @journal_entries.where(client: @client)
    end
    @journal_entries = @journal_entries.includes(client: :user).order(created_at: :desc, id: :desc)
  end

  def show
  end

  def new
    build_journal_entry
  end

  def create
    build_journal_entry
    @journal_entry.assign_attributes(journal_entry_params)
    if @journal_entry.save
      redirect_to @journal_entry, notice: "Journal entry created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @journal_entry.update(journal_entry_params)
      redirect_to @journal_entry, notice: "Journal entry updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @journal_entry.destroy!
    redirect_to journal_entries_path, notice: "Journal entry deleted.", status: :see_other
  end

  private

  def build_journal_entry
    @journal_entry = JournalEntry.new(client: current_user.client)
    authorize @journal_entry, :create?
  end

  def set_journal_entry
    @journal_entry = policy_scope(JournalEntry).find(params[:id])
    authorize @journal_entry
  end

  def journal_entry_params
    params.expect(journal_entry: [ :text ])
  end
end
