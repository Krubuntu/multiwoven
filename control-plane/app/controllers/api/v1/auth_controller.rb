# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      before_action :authenticate_user!, only: [:logout]

      def login
        service = AuthenticationService.new(params)
        token = service.login

        if token
          render json: { token: }, status: :ok
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def signup
        result = AuthenticationService.new(params).signup

        if result[:success]
          render json: { message: result[:message] }, status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      def logout
        service = AuthenticationService.new(params)
        result = service.logout(current_user)

        if result[:success]
          render json: { message: result[:message] }, status: :ok
        else
          render json: { error: result[:errors] }, status: :internal_server_error
        end
      end

      def forgot_password
        user = User.find_by(email: params[:email])

        if user
          user.send_reset_password_instructions
          render json: { message: "Reset password instructions sent to email." }, status: :ok
        else
          render json: { error: "Email not found" }, status: :not_found
        end
      end

      def reset_password
        user = User.with_reset_password_token(params[:reset_password_token])

        if user&.reset_password(params[:password], params[:password_confirmation])
          render json: { message: "Password successfully reset." }, status: :ok
        else
          render json: { error: "Invalid token or password mismatch." }, status: :unprocessable_entity
        end
      end

      def verify_code
        user = User.find_by(email: params[:email])

        if user&.confirmation_code == params[:confirmation_code]
          user.update!(confirmed_at: Time.current, confirmation_code: nil)
          render json: { message: "Account verified successfully!" }, status: :ok
        else
          render json: { error: "Invalid confirmation code." }, status: :unprocessable_entity
        end
      end
    end
  end
end