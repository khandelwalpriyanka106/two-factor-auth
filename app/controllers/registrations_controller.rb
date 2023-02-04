class RegistrationsController < ApplicationController
  # instantiates new user
  def new
    @user = User.new
  end
  def create
    @user = User.new(user_params)
    # totp = ROTP::TOTP.new("base32secret3232", issuer: "TwoFactAuth"
    # @user.otp_secret = totp.now
    if @user.save
      # WelcomeMailer.with(user: @user).welcome_email.deliver_now
      # deliver_now is provided by ActiveJob.
      session[:user_id] = @user.id
      @otp_secret = ROTP::Base32.random
        totp = ROTP::TOTP.new(
        @otp_secret, issuer: 'TwoFactAuth'
      )
      @qr_code = RQRCode::QRCode
        .new(totp.provisioning_uri(current_user.email))
        .as_png(resize_exactly_to: 200)
        .to_data_url

      render 'otp_secrets/new'
      # redirect_to root_path, notice: 'Successfully created account'
    else
      render :new
    end
  end

  private
  def user_params
    # strong parameters
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
