require 'google/api_client'

class User < ActiveRecord::Base

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable

  TEMP_EMAIL_PREFIX = 'change@me'
  TEMP_EMAIL_REGEX = /\Achange@me/

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :omniauthable

  validates_format_of :email, :without => TEMP_EMAIL_REGEX, on: :update
  has_many :identities, dependent: :destroy

  def self.from_omniauth(auth, current_user)
    identity = Identity.where(:provider => auth.provider, :uid => auth.uid.to_s).first_or_initialize
    if identity.user.blank?
      user = current_user || User.where('email = ?', auth["info"]["email"]).first
      if user.blank?
        user = User.new
        user.password = Devise.friendly_token[0,10]
        user.username = auth.info.name
        user.email = auth.info.email ||  "#{TEMP_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com"
        if auth.provider == "twitter"
          user.save(:validate => false)
        elsif auth.provider  == "google_oauth2"
          @token = auth["credentials"]["token"]
          client = Google::APIClient.new
          client.authorization.access_token = @token
          service = client.discovered_api('calendar', 'v3')
          debugger
          @result = client.execute(
              :api_method => service.calendar_list.list,
              :parameters => {},
              :headers => {'Content-Type' => 'application/json'})

          puts "calender events =   #{@result.data}"
          user.save
        else
          user.save
        end
      end

      identity.user_id = user.id
      identity.save
    end
    identity.user
  end

end
