module Validators
  module Accounts
    class Create < ActiveModel::Validator
      AREA_ID_REGEX = /\A\d+\z/

      def validate(record)
        validate_area(record)
      end

      private
        def validate_area(record)
          area = record.area
          return if area.nil?

          unless area.is_a?(Array)
            record.errors.add(:area, "must be an array")
            return
          end

          return if area.all? { |id| id.to_s.match?(AREA_ID_REGEX) }

          record.errors.add(:area, "must contain only numeric ids")
        end
    end
  end
end
