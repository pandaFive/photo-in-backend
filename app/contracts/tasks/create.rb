# frozen_string_literal: true

module Contracts
  module Tasks
    class Create
      include ActiveModel::Model

      attr_accessor :task_title, :area_id

      validates :task_title, presence: true, length: { maximum: 256 }

      def self.call(params)
        contract = new(
          task_title: params[:task_title],
          area_id: params[:area_id]
        )

        if contract.valid?
          Result.new(success?: true, value: contract.normalized_attributes, errors: [])
        else
          Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      def normalized_attributes
        {
          task_title:,
          area_id: area_id.present? ? area_id.to_i : nil
        }
      end
    end
  end
end
