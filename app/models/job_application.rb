class JobApplication < ActiveRecord::Base
  include Queryable

  attr_accessor :company_name

  belongs_to :company
  belongs_to :user
  has_many :notes, as: :notable, dependent: :destroy
  has_one :posting, inverse_of: :job_application, dependent: :destroy, class_name: 'JobApplications::Posting'
  has_one :cover_letter, inverse_of: :job_application, dependent: :destroy, class_name: 'JobApplications::CoverLetter'

  validates :user, presence: true

  # scopes
  scope :belonging_to_user, -> (user_id) { where(user_id: user_id) }
  scope :sorted, -> { order(updated_at: :desc) }

  # class methods

  # A named scope for selecting active or inactive job applications
  # @param show_active [Boolean], show active or inactive records
  # @return list of job applications
  def self.active(active = nil)
    if active
      where(active: active)
    else
      where(nil)
    end
  end

  # Return a list of job applications that match a title
  # Works as long as title has a company w/ a name & a posting w/ a job_title
  # Won't work if either of those bits of info is missing
  # @param title [String], generated by #title
  # @param [ActiveRecord::Relation], a list of matching JobApplication records
  def self.find_by_title(title)
    # parse the title
    title_as_arr = title.split(' - ')
    company_name = title_as_arr.first
    job_title = title_as_arr.second

    # find some matches
    joins(:company, :posting)
      .where(companies: { name: company_name })
      .where(postings: { job_title: job_title })
  end

  # instance methods
  def title
    title = if company.present?
              company.name
            else
              Time.now.utc.strftime('%Y%m%d%H%M%S')
            end

    title += " - #{posting.job_title}" if posting.present?

    title
  end

  def company_name
    company.name if company.present?
  end
end
