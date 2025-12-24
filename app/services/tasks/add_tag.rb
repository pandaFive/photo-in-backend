# frozen_string_literal: true

module Services
  module Tasks
    # タスクへのタグ追加
    class AddTag
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        # 認証チェック
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        # Contract検証
        validation = ::Contracts::Tasks::AddTag.call(params)
        return failure(validation.errors, :unprocessable_entity) unless validation.success?

        # 認可チェック（管理者のみ）
        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(["権限がありません"], :forbidden) unless policy.admin_only?

        value = validation.value

        # タスク取得
        task = @repository.find_by_id(value[:task_id])
        return failure(["タスクが見つかりません"], :not_found) if task.nil?

        # タグ取得
        tag = @repository.find_tag(value[:tag_id])
        return failure(["タグが見つかりません"], :not_found) if tag.nil?

        # タグ追加（冪等: 既に存在する場合はスキップ）
        @repository.add_tag(task, tag)

        success(task)
      end

      private
        def success(task)
          Result.new(success?: true, task:, tasks: nil, errors: [], status: :ok)
        end

        def failure(errors, status)
          Result.new(success?: false, task: nil, tasks: nil, errors:, status:)
        end
    end
  end
end
