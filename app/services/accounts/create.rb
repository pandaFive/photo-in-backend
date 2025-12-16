module Accounts
  class Create
    Result = Struct.new(:success?, :account, :errors, :status, keyword_init: true)

    def initialize(repository: Repository.new)
      @repository = repository
    end

    def call(params)
      account = @repository.build(
        name: params[:name],
        password: params[:password],
        role: params[:role],
        capacity: params[:capacity] || 0
      )

      areas = @repository.find_areas(params[:area_ids])
      missing_ids = missing_area_ids(params[:area_ids], areas)
      return failure(account, ["Area not found: #{missing_ids.join(', ')}"], :not_found) if missing_ids.present?

      Account.transaction do
        @repository.assign_areas(account, areas)
        return failure(account, account.errors.full_messages, :unprocessable_entity) unless @repository.save(account)
      end

      Result.new(success?: true, account:, errors: [], status: :created)
    end

    private

    def missing_area_ids(requested_ids, found_areas)
      ids = Array(requested_ids).compact.map(&:to_i).uniq
      return [] if ids.empty?

      ids - found_areas.pluck(:id)
    end

    def failure(account, errors, status)
      Result.new(success?: false, account:, errors:, status:)
    end
  end
end
