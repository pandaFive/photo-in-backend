# frozen_string_literal: true

module Presenters
  class AreaPresenter
    class << self
      def render_area(area)
        raise ArgumentError, "AreaPresenter.render_area received nil area" if area.nil?

        { id: area.id, name: area.name }
      end

      def render_areas(areas)
        raise ArgumentError, "AreaPresenter.render_areas received nil areas" if areas.nil?

        areas.map { |area| render_area(area) }
      end
    end
  end
end
