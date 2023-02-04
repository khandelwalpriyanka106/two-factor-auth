class OtpSecretsController < ApplicationController
  def new
    @otp_secret = ROTP::Base32.random
    totp = ROTP::TOTP.new(
      @otp_secret, issuer: 'TwoFactAuth'
    )
    @qr_code = RQRCode::QRCode
      .new(totp.provisioning_uri(current_user.email))
      .as_png(resize_exactly_to: 200)
      .to_data_url
  end

  def create
    @otp_secret = params[:otp_secret]
    totp = ROTP::TOTP.new(
      @otp_secret, issuer: 'TwoFactAuth'
    )
    last_otp_at = totp.verify(params[:otp_attempt], drift_behind: 15 )
    if last_otp_at
      current_user.update(
        otp_secret: @otp_secret, last_otp_at: last_otp_at
      )
      redirect_to(
        root_path,
        # after_otp_configuration_path,
        notice: 'Successfully configured OTP protection for your account'
      )
    else
      flash.now[:alert] = 'The code you provided was invalid!'
      @qr_code = RQRCode::QRCode
        .new(totp.provisioning_uri(current_user.email))
        .as_png(resize_exactly_to: 200)
        .to_data_url
      render :new
    end
  end
end
