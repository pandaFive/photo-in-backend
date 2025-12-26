# frozen_string_literal: true

module Services
  module Tags
    # タグ作成サービス
    #
    # 認可: admin のみ
    class Create
      def initialize(repository: Repository.new)
        @repository = repository
      end

      # @param params [Hash] { tag: { name: String } } または { name: String }
      # @param current_account [Account, nil] 現在のログインユーザー
      # @return [Result]
      def call(params, current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        validation = ::Contracts::Tags::Create.call(params)
        unless validation.success?
          Rails.logger.warn "Tag create validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        policy = ::Policies::TagPolicy.new(current_account)
        unless policy.admin_only?
          Rails.logger.warn "Tag create unauthorized: account_id=#{current_account.id}, role=#{current_account.role}"
          return failure(["権限がありません"], :forbidden)
        end

        tag = @repository.build(name: validation.value[:name])
        unless @repository.save(tag)
          Rails.logger.warn "Tag create failed: name=#{validation.value[:name]}, errors=#{tag.errors.full_messages.join(', ')}, by_account=#{current_account.id}"
          return failure(tag.errors.full_messages, :unprocessable_entity)
        end

        Rails.logger.info "Tag created: id=#{tag.id}, name=#{tag.name}, by_account=#{current_account.id}"
        Result.new(success?: true, tag:, errors: [], status: :created)
      rescue ActiveRecord::RecordNotUnique => e
        Rails.logger.error "Tag create uniqueness error: #{e.message}"
        failure(["このタグは既に存在します"], :conflict)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Tag create DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, tag: nil, errors:, status:)
        end
    end
  end
end
