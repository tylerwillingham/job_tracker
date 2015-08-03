class User < ActiveRecord::Base
  attr_accessor :remember_token

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  has_many :job_applications

  has_secure_password

  # model validations
  validates :first_name,
    presence: true
  validates :last_name,
    presence: true
  validates :email,
    presence: true,
    length: { maximum: 255 },
    format: { with: VALID_EMAIL_REGEX },
    uniqueness: { :case_sensitive => false }
  validates :password,
    allow_nil: true,
    length: { minimum: 6 }

  before_save :downcase_email

  # class methods

  def self.digest(string)
    # return hash digest of a string
    cost = ActiveModel::SecurePassword.min_cost ?
      BCrypt::Engine::MIN_COST :
      BCrypt::Engine.cost
    BCrypt::Password.create(string, :cost => cost)
  end
  
  def self.new_token
    # return a random token
    SecureRandom.urlsafe_base64
  end

  # instance methods, account & session-related

  def name
    "#{self.first_name} #{self.last_name}"
  end

  def remember
    # remember a user in the database for use in persistent sessions
    # make #remember_token available w/o storing the actual token in the db.
    # instead, we are storing the encrypted hash in the db.
    self.remember_token = self.class.new_token
    update_attribute(:remember_digest, self.class.digest(remember_token))
  end

  def forget
    update_attribute(:remember_digest, nil)
  end

  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil? 

    # returns true if the given token matches the digest
    BCrypt::Password.new(digest).is_password?(token)
  end

  private
    def downcase_email
      self.email = email.downcase
    end
end
