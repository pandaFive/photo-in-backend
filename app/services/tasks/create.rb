module Services
  module Tasks
    class Create
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        # 1. Contract検証
        validation = ::Contracts::Tasks::Create.call(params)
        return failure(nil, validation.errors, :unprocessable_entity) unless validation.success?

        # 2. 認可チェック（adminのみ）
        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(nil, ["権限がありません"], :forbidden) unless policy.admin_only?

        # 3. エリアの解決（指定 > 推論 > デフォルト）
        value = validation.value
        area_id = resolve_area_id(value[:task_title], value[:area_id])

        if area_id.nil?
          return failure(nil, ["エリアが正しく設定されていません"], :bad_request)
        end

        # 4. タスク作成
        task = @repository.build(task_title: value[:task_title], area_id:)

        unless @repository.save(task)
          return failure(task, task.errors.full_messages, :unprocessable_entity)
        end

        # 5. AssignCycle作成 & アサイン
        cycle = task.create_new_cycle
        unless cycle.assign
          return failure(task, ["アサイン可能なアカウントがありません"], :unprocessable_entity)
        end

        Result.new(success?: true, task:, errors: [], status: :created)
      end

      private
        # エリアIDの解決: 指定値 > タイトルから推論 > デフォルト
        def resolve_area_id(task_title, provided_area_id)
          return provided_area_id if provided_area_id.present?

          @repository.infer_area_id(task_title) || @repository.default_area_id
        end

        def failure(task, errors, status)
          Result.new(success?: false, task:, errors:, status:)
        end
    end
  end
end
