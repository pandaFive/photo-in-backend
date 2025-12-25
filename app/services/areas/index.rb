# frozen_string_literal: true

module Services
  module Areas
    class Index
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        areas = @repository.all_areas
        Result.new(success?: true, areas:, errors: [], status: :ok)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, areas: nil, errors:, status:)
        end
    end
  end
end
