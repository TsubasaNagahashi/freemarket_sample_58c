class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  devise :omniauthable,omniauth_providers: [:facebook, :google_oauth2]
  has_many :sns_credentials, dependent: :destroy

  has_one :deliver_address ,dependent: :destroy
  accepts_nested_attributes_for :deliver_address, allow_destroy: true
  

  has_many :cards


def self.without_sns_data(auth)
  user = User.where(email: auth.info.email).first

    if user.present?
      sns = SnsCredential.create(
        uid: auth.uid,
        provider: auth.provider,
        user_id: user.id
      )
    else
      user = User.new(
        nickname: auth.info.name,
        email: auth.info.email,
        password: Devise.friendly_token[0, 20]
      )
      sns = SnsCredential.new(
        uid: auth.uid,
        provider: auth.provider
      )
    end
    return { user: user ,sns: sns}
  end

 def self.with_sns_data(auth, snscredential)
  user = User.where(id: snscredential.user_id).first
  unless user.present?
    user = User.new(
      nickname: auth.info.name,
      email: auth.info.email,
      password: Devise.friendly_token[0, 20]
    )
  end
  return {user: user}
 end

 def self.find_oauth(auth)
  uid = auth.uid
  provider = auth.provider
  snscredential = SnsCredential.where(uid: uid, provider: provider).first
  if snscredential.present?
    user = with_sns_data(auth, snscredential)[:user]
    sns = snscredential
  else
    user = without_sns_data(auth)[:user]
    sns = without_sns_data(auth)[:sns]
  end
  return { user: user ,sns: sns}
end

end