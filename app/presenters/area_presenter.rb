# frozen_string_literal: true

module Presenters
  class AreaPresenter
    class << self
      def render_area(area)
        { id: area.id, name: area.name }
      end

      def render_areas(areas)
        areas.map { |area| render_area(area) }
      end
    end
  end
end
