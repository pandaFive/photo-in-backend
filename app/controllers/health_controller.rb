# frozen_string_literal: true

class HealthController < ApplicationController
  def show
    render json: { message: "OK" }, status: 200
  end
end
