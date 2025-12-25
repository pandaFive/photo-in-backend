# frozen_string_literal: true

module Services
  module Accounts
    # アカウント作成ユースケース
    #
    # 管理者のみ実行可能。エリア関連付けも同時に行う
    class Create
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        # 認証チェック
        return failure(nil, ["認証が必要です"], :unauthorized) if current_account.nil?

        # Contract検証
        validation = ::Contracts::Accounts::Create.call(params)
        unless validation.success?
          Rails.logger.warn "Account create validation failed: #{validation.errors.join(', ')}"
          return failure(nil, validation.errors, :unprocessable_entity)
        end

        # 認可チェック（admin_only）
        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(nil, ["権限がありません"], :forbidden) unless policy.admin_only?

        # アカウント構築
        value = validation.value
        account = @repository.build(
          name: value[:name],
          password: value[:password],
          role: value[:role],
          capacity: value[:capacity] || 0
        )

        # エリア検証
        areas = @repository.find_areas(value[:area_ids])
        missing_ids = missing_area_ids(value[:area_ids], areas)
        return failure(account, ["エリアが見つかりません: #{missing_ids.join(', ')}"], :not_found) if missing_ids.present?

        # トランザクション内で保存
        saved = false
        begin
          Account.transaction do
            @repository.assign_areas(account, areas)
            saved = @repository.save(account)
            raise ActiveRecord::Rollback unless saved
          end
        rescue ActiveRecord::StatementInvalid, ActiveRecord::InvalidForeignKey => e
          Rails.logger.error "Account create DB error: #{e.class} - #{e.message}"
          return failure(account, ["データベースエラーが発生しました"], :internal_server_error)
        end

        return failure(account, account.errors.full_messages.presence || ["保存に失敗しました"], :unprocessable_entity) unless saved

        Rails.logger.info "Account created: id=#{account.id}, name=#{account.name}, role=#{account.role}, by_account=#{current_account.id}"
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
