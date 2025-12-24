# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tasks::RemoveTag, type: :service do
  describe "#call" do
    let!(:admin) { create(:account, role: "admin") }
    let!(:member) { create(:account_member) }
    let!(:area) { create(:area) }
    let!(:target_task) { create(:task, area:) }
    let!(:tag) { create(:tag, name: "重要") }

    let(:valid_params) do
      { task_id: target_task.id, tag_id: tag.id }
    end

    describe "正常系" do
      before { target_task.tags << tag }

      context "adminユーザーがタグを削除する場合" do
        it "成功を返すこと" do
          result = described_class.new.call(valid_params, admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
          expect(result.errors).to be_empty
        end

        it "タスクからタグが削除されること" do
          expect {
            described_class.new.call(valid_params, admin)
          }.to change { target_task.tags.count }.by(-1)
        end

        it "更新されたタスクを返すこと" do
          result = described_class.new.call(valid_params, admin)

          expect(result.task).to eq(target_task)
          expect(result.task.tags).not_to include(tag)
        end
      end

      context "idパラメータを使用する場合（ルート互換性）" do
        it "成功を返すこと" do
          params = { id: target_task.id, tag_id: tag.id }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be true
        end
      end
    end

    describe "正常系（タグが追加されていない場合）" do
      context "タグが追加されていない場合" do
        it "成功を返すこと（冪等性）" do
          result = described_class.new.call(valid_params, admin)

          expect(result.success?).to be true
        end

        it "タグの数が変わらないこと" do
          expect {
            described_class.new.call(valid_params, admin)
          }.not_to change { target_task.tags.count }
        end
      end
    end

    describe "異常系" do
      context "認証エラーの場合" do
        context "current_accountがnilの場合" do
          it "unauthorizedを返すこと" do
            result = described_class.new.call(valid_params, nil)

            expect(result.success?).to be false
            expect(result.status).to eq(:unauthorized)
            expect(result.errors).to include("認証が必要です")
          end

          it "タグが削除されないこと" do
            target_task.tags << tag
            expect {
              described_class.new.call(valid_params, nil)
            }.not_to change { target_task.tags.count }
          end
        end
      end

      context "バリデーションエラーの場合" do
        it "task_idが空の場合、失敗を返すこと" do
          params = { task_id: nil, tag_id: tag.id }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
          expect(result.errors).not_to be_empty
        end

        it "tag_idが空の場合、失敗を返すこと" do
          params = { task_id: target_task.id, tag_id: nil }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "task_idが数値でない場合、失敗を返すこと" do
          params = { task_id: "abc", tag_id: tag.id }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "タグが削除されないこと" do
          target_task.tags << tag
          params = { task_id: nil, tag_id: tag.id }
          expect {
            described_class.new.call(params, admin)
          }.not_to change { target_task.tags.count }
        end
      end

      context "権限エラーの場合" do
        context "memberユーザーの場合" do
          it "forbiddenを返すこと" do
            result = described_class.new.call(valid_params, member)

            expect(result.success?).to be false
            expect(result.status).to eq(:forbidden)
            expect(result.errors).to include("権限がありません")
          end

          it "タグが削除されないこと" do
            target_task.tags << tag
            expect {
              described_class.new.call(valid_params, member)
            }.not_to change { target_task.tags.count }
          end
        end
      end

      context "タスクが存在しない場合" do
        it "not_foundを返すこと" do
          params = { task_id: 999999, tag_id: tag.id }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:not_found)
          expect(result.errors).to include("タスクが見つかりません")
        end
      end

      context "タグが存在しない場合" do
        it "not_foundを返すこと" do
          params = { task_id: target_task.id, tag_id: 999999 }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:not_found)
          expect(result.errors).to include("タグが見つかりません")
        end
      end
    end

    describe "処理順序の検証" do
      it "認証 → バリデーション → 認可 → タスク検索 → タグ検索 → 削除の順序で処理されること" do
        # 認証エラーはバリデーション前に返される
        result_unauth = described_class.new.call({ task_id: nil, tag_id: nil }, nil)
        expect(result_unauth.status).to eq(:unauthorized)

        # バリデーションエラーは認可チェック前に返される
        result_invalid = described_class.new.call({ task_id: nil, tag_id: nil }, admin)
        expect(result_invalid.status).to eq(:unprocessable_entity)

        # 認可エラーは存在チェック前に返される（存在しないIDでも403）
        result_forbidden = described_class.new.call({ task_id: 999999, tag_id: 999999 }, member)
        expect(result_forbidden.status).to eq(:forbidden)

        # タスクが存在しない場合はnot_foundを返す
        result_task_not_found = described_class.new.call({ task_id: 999999, tag_id: tag.id }, admin)
        expect(result_task_not_found.status).to eq(:not_found)
        expect(result_task_not_found.errors).to include("タスクが見つかりません")

        # タグが存在しない場合はnot_foundを返す
        result_tag_not_found = described_class.new.call({ task_id: target_task.id, tag_id: 999999 }, admin)
        expect(result_tag_not_found.status).to eq(:not_found)
        expect(result_tag_not_found.errors).to include("タグが見つかりません")
      end
    end

    describe "Repository DI" do
      before { target_task.tags << tag }

      it "カスタムRepositoryを受け取れること" do
        mock_repository = instance_double(Services::Tasks::Repository)
        allow(mock_repository).to receive(:find_by_id).with(target_task.id).and_return(target_task)
        allow(mock_repository).to receive(:find_tag).with(tag.id).and_return(tag)
        allow(mock_repository).to receive(:remove_tag).with(target_task, tag).and_return(true)

        service = described_class.new(repository: mock_repository)
        result = service.call(valid_params, admin)

        expect(result.success?).to be true
        expect(mock_repository).to have_received(:find_by_id).with(target_task.id)
        expect(mock_repository).to have_received(:find_tag).with(tag.id)
        expect(mock_repository).to have_received(:remove_tag).with(target_task, tag)
      end
    end
  end
end
