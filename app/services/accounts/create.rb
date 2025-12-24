# frozen_string_literal: true

module Services
  module Accounts
    class Create
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        validation = ::Contracts::Accounts::Create.call(params)
        return failure(nil, validation.errors, :unprocessable_entity) unless validation.success?

        policy = ::Policies::AccountPolicy.new(current_account)

        return failure(nil, ["権限がありません"], :forbidden) unless policy.admin_only?

        value = validation.value
        account = @repository.build(
          name: value[:name],
          password: value[:password],
          role: value[:role],
          capacity: value[:capacity] || 0
        )

        areas = @repository.find_areas(value[:area_ids])
        missing_ids = missing_area_ids(value[:area_ids], areas)
        return failure(account, ["Area not found: #{missing_ids.join(', ')}"], :not_found) if missing_ids.present?

        saved = false
        Account.transaction do
          @repository.assign_areas(account, areas)
          saved = @repository.save(account)
          raise ActiveRecord::Rollback unless saved
        end

        return failure(account, account.errors.full_messages, :unprocessable_entity) unless saved

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
end
