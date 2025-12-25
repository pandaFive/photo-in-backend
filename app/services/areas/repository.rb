# frozen_string_literal: true

module Services
  module Areas
    class Repository
      def all_areas
        Area.select(:id, :name)
      end

      def find_by_id(id)
        Area.find_by(id:)
      end

      def find_by_id_with_lock(id)
        Area.lock.find_by(id:)
      end

      def build(attrs)
        Area.new(attrs)
      end

      def save(area)
        area.save
      end

      def update(area, attrs)
        area.update(attrs)
      end

      def destroy(area)
        area.destroy
      end
    end
  end
end
